paths.dofile('layers/Residual.lua')

local function hourglass(n, f, inp)
    -- Upper branch
    local up1 = inp
    for i = 1,opt.nModules do up1 = Residual(f,f)(up1) end

    -- Lower branch
    local low1 = cudnn.SpatialMaxPooling(2,2,2,2)(inp)
    for i = 1,opt.nModules do low1 = Residual(f,f)(low1) end
    local low2

    if n > 1 then low2 = hourglass(n-1,f,low1)
    else
        low2 = low1
        for i = 1,opt.nModules do low2 = Residual(f,f)(low2) end
    end

    local low3 = low2
    for i = 1,opt.nModules do low3 = Residual(f,f)(low3) end
    local up2 = nn.SpatialUpSamplingNearest(2)(low3)

    -- Bring two branches together
    return nn.CAddTable()({up1,up2})
end

local function lin(numIn,numOut,inp)
    -- Apply 1x1 convolution, stride 1, no padding
    local l = cudnn.SpatialConvolution(numIn,numOut,1,1,1,1,0,0)(inp)
    return cudnn.ReLU(true)(nn.SpatialBatchNormalization(numOut)(l))
end

local function upsampling(res)
    local upsampling = nn.Sequential()
    upsampling:add(nn.SpatialUpSamplingBilinear({oheight=res, owidth=res}))
    upsampling:add(cudnn.ReLU(true))
    upsampling:add(cudnn.SpatialConvolution(opt.nOutChannels, opt.nOutChannels, 3, 3, 1, 1, 1, 1))
    cudnn.convert(upsampling, cudnn)
    return upsampling
end

function createModelScratch()

    local inp = nn.Identity()()

    local segm = nn.SelectTable(1)(inp)                                           -- 15 x 256 x 256
    local joints3D = nn.SelectTable(2)(inp)                                       -- 65 x 64 x 64

    -- Initial processing of the image
    local cnv1_
    if(opt.applyHG == 'segm15joints3D') then
        cnv1_ = cudnn.SpatialConvolution(15,64,7,7,2,2,3,3)(segm)                 -- 128
    elseif(opt.applyHG == 'rgbsegm15joints2Djoints3D') then
        cnv1_ = cudnn.SpatialConvolution(3+15+#opt.jointsIx,64,7,7,2,2,3,3)(segm) -- 128
    else
        cnv1_ = cudnn.SpatialConvolution(opt.inSize[1][1],64,7,7,2,2,3,3)(segm)   -- 64 x 128 x 128
    end
 
    local cnv1 = cudnn.ReLU(true)(nn.SpatialBatchNormalization(64)(cnv1_))
    local r1 = Residual(64,128)(cnv1)
    local pool = cudnn.SpatialMaxPooling(2,2,2,2)(r1)                             -- 64

    local pool_concat = nn.JoinTable(2)({pool, joints3D})                         --(128 + 16 * 65) x 64 x 64

    local r4 = Residual(128+#opt.jointsIx*opt.depthClasses,128)(pool_concat)
    local r5 = Residual(128,opt.nFeats)(r4)

    local out = {}
    local inter = r5

    for i = 1,opt.nStack do
        local hg = hourglass(4,opt.nFeats,inter)

        -- Residual layers at output resolution
        local ll = hg
        for j = 1,opt.nModules do ll = Residual(opt.nFeats,opt.nFeats)(ll) end
        -- Linear layer to produce first set of predictions
        ll = lin(opt.nFeats,opt.nFeats,ll)

        -- Predicted heatmaps
        local tmpOut = cudnn.SpatialConvolution(opt.nFeats,opt.nOutChannels,1,1,1,1,0,0)(ll)

        local tmpOutHigh = upsampling(opt.nVoxels)(tmpOut)
        local tmpOutSigmoid = nn.Sigmoid()(tmpOutHigh)
        -- If    intermediate supervision: add
        -- If no intermediate supervision: add if this is the last stack
        if(  opt.intsup  or  ( (i == opt.nStack) and (not opt.intsup) )  ) then
            if(opt.supervision == 'partvoxels') then
                print('View')
                table.insert(out, nn.View(opt.nParts3D, opt.nVoxels, opt.nVoxels, opt.nVoxels)(tmpOutSigmoid))
            else
                table.insert(out,tmpOutSigmoid)
            end
        end

        -- Add predictions back
        if i < opt.nStack then
            local ll_ = cudnn.SpatialConvolution(opt.nFeats,opt.nFeats,1,1,1,1,0,0)(ll)
            local tmpOut_ = cudnn.SpatialConvolution(opt.nOutChannels,opt.nFeats,1,1,1,1,0,0)(tmpOut)
            inter = nn.CAddTable()({inter, ll_, tmpOut_})
        end
    end

    -- Final model
    local model = nn.gModule({inp}, out)

    print('Return hg (img + joints3D) => voxels')
    return model
end

-- Pretrained
function createModel()
    assert(opt.proj == 'silhFV' or opt.proj == 'silhFVSV'
        or opt.proj == 'segmFV' or opt.proj == 'segmFVSV')

    inp = nn.Identity()()
    local pretrained

    assert(opt.input == 'rgbsegm15joints2Djoints3D' or opt.applyHG == 'rgbsegm15joints2Djoints3D')
    if(opt.scratchproj) then
        pretrained = createModelScratch()
        print('From scratch.')
    else
        pretrained = torch.load(opt.modelVoxels)
        print('Pre-trained. ' .. opt.modelVoxels)
    end

    voxels = (pretrained)(inp)

    local out = {}
    for st = 1, opt.nStack do

        local curr_voxels = nn.SelectTable(st)(voxels)
        -- this should be removed for foreground voxels!
        table.insert(out, nn.View(-1, opt.nParts3D, 128, 128, 128)(curr_voxels))

        local projFV, projSV
        local sig, bg, parts

        -- Always add front view projection
        if(opt.proj == 'silhFV' or opt.proj == 'silhFVSV') then
            -- Take max over the z dimension to approximate front view projection
            print('Add front view silhouette projection.')
            silhFV = nn.Max(1, 3):cuda()(curr_voxels) -- zyx
            table.insert(out, silhFV)
        elseif(opt.proj == 'segmFV' or opt.proj == 'segmFVSV') then
            print('Add front view parts projection.')
            sig = nn.Sigmoid():cuda()(curr_voxels)
            bg = nn.View(-1, 1, 128, 128, 128)(nn.Select(2, 1)(sig)) -- bg -- nn.Select(dimension, index)
            parts = nn.Narrow(2, 2, opt.nParts3D-1)(sig) -- parts nn.Narrow(dimension, offset, length)
            local bgproj = nn.Min(2, 4):cuda()(bg)
            local partsproj = nn.Max(2, 4):cuda()(parts) -- nn.Max(dimension, nInputDim)
            silhFV = nn.JoinTable(1, 3)({bgproj, partsproj}) -- dimension, ninputdims
            table.insert(out, silhFV)
        end

        if(opt.proj == 'silhFVSV') then
            -- Take max over the x dimension to approximate front view projection
            print('Add side view silhouette projection.')
            silhSV = nn.Max(3, 3):cuda()(curr_voxels) -- zyx
            table.insert(out, silhSV)
        elseif(opt.proj == 'segmFVSV') then
            print('Add side view parts projection.')
            local bgproj = nn.Min(4, 4):cuda()(bg)
            local partsproj = nn.Max(4, 4):cuda()(parts)
            silhSV = nn.JoinTable(1, 3)({bgproj, partsproj})
            table.insert(out, silhSV)
        end
    end

    -- Final model
    local model = nn.gModule({inp}, out)

    print('Return pretrained hg (img + joints3D) => voxels (proj)')
    return model
end

