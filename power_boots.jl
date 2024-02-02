using Statistics
using Random
using StatsBase
using Dates
using Printf
p0 = zeros(100)
p1 = zeros(100)
p0[begin:5] .= 1.
p1[begin:6] .= 1.
effectSize = abs(mean(p0) - mean(p1))

function printProcess(i::AbstractFloat;len::Int=50,printPercentage::Bool=false,est_ns=0)::Nothing
    k::Int = floor(i*len)
    tails=String["","▏","▎","▍","▌","▋","▊","▉"]
    re::Int = floor((i*len - k)*8)
    tail::String = tails[re+1]
    spa::Int = len-k-length(tail)
    if spa<0 spa=0 end
    print("\r▕$("█"^k)$(tail)$(" "^spa)▎")#░
    eta_ns = est_ns*(1-i)
    min = eta_ns/1e9÷60
    sec = eta_ns/1e9%60
    if printPercentage print("$(@sprintf("%.2f",i*100))%", @sprintf(" ETA %d min %.0f s          ", min, sec)) end
    #print("\r")
end
function printProcess(i::Int,N::Int;len::Int=50,printPercentage::Bool=false, est_ns=0)::Nothing
    printProcess(i/N;len=len,printPercentage=printPercentage,est_ns=est_ns)
end
flushProcess(i::Int=60)::Nothing = print("\r$(" "^i)\r")

function fisher_yates_shuffle!(a, k)
    @inbounds for i = 1:k
        j = rand(Random.GLOBAL_RNG, i:length(a))
        t = a[j]
        a[j] = a[i]
        a[i] = t
    end
end

function permFun(x, nA, nB, rounds, doubleSiteTest = true)
    k = nA<nB ? nA : nB
    ret = zeros(rounds)
    @inbounds for reti = 1:rounds
        fisher_yates_shuffle!(x, k)

        @views x1 = x[begin:k]
        @views x2 = x[k+1:end]
        diff = mean(x1) - mean(x2)
        # diff = mean(x[begin:k]) - mean(x[k+1:end])
        
        ret[reti] = doubleSiteTest ? abs(diff) : diff
    end
    return ret
end

function bootstrapN(p0, p1, startN=1000, endN=2000, step=200; α=0.05, powerN=10000, permN=10000)
    power = []
    for sampleSize = startN:step:endN
        β = zeros(powerN)
        println("sameple size = $(sampleSize)")
        println("power N = $(powerN)")
        println("perm N = $(permN)")
        j = Threads.Atomic{Int}(0)
        @time begin 
            Threads.@threads for i = 1:powerN
                # 在p0、p1两个总体上boostrap抽取n+n的样本
                l = [sample(p0, sampleSize); sample(p1, sampleSize)]
                # 在n的合并样本上进行10000次置换计算差异
                perm_diffs = permFun(l, sampleSize, sampleSize, permN)
                # 计算差异大于效应量的频率
                β[i] = length(filter(d->d>effectSize, perm_diffs))/length(perm_diffs)

                Threads.atomic_add!(j, 1)
                printProcess(j[], powerN)
            end
            flushProcess()
        end
        poweri = length(filter(b->b<α, β))/length(β)
        push!(power, (sampleSize*2, poweri))
    end
    return power
end

#@ProfileSVG.profview bootstrapN(p0, p1, 1000, 1000, 1, powern=100)
println("使用 $(Threads.nthreads()) 个线程")
power = bootstrapN(p0, p1, 1000, 1000, 1; powerN=1000)
for (sampleSize, poweri) in power
    if poweri > 0.8
        @printf "当样本量为%d时，置换检验的p值为显著性的概率POWER为%f\n" sampleSize poweri
    else
        @printf "当样本量为%d时，POWER=%f\n" sampleSize poweri
    end
end




"""
