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
        diff = mean(x[begin:k]) - mean(x[k+1:end])
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

干杯d3 2022/12/31 14:44:52
《2022年年度总结报告》之年度之最
年度最佳护士:
1、ssni-369 ：magnet:?xt=urn:btih:49BD0756C34B2B3EBEBA1C86120DB2BE6EDC52F2
2、ipx-134：magnet:?xt=urn:btih:F12551B91BAB14F5CE0995C0074794C483E83B25
3、ipz-462：magnet:?xt=urn:btih:FD959F8CA147CD66ECDA34E54917A785FE7D09B3
4、ipx-236 ：magnet:?xt=urn:btih:5AA858D9256633910B076D34FDF93B83DAB1D86E
5、ipx-185：magnet:?xt=urn:btih:846974BAF9FCAE7B9A4219E458DF76E639AA5B9C

年度最佳女仆:
1、ssni-071：magnet:?xt=urn:btih:CDE45D798866338C4B0DD21C80EDFACC39CF65A4
2、ipx-118：magnet:?xt=urn:btih:AE4835A5F84B2A006CE81BDDAE490B589C4529F7
3、snis-854 ：magnet:?xt=urn:btih:9A44EC1CFF98A1DE7A2E042A8D503E4299EEEFAE
4、ipx-238 ：magnet:?xt=urn:btih:82310C37173932ABC8CBC496A873A7BE89DFE4D7
5、onez-103 ：magnet:?xt=urn:btih:6913E3CDDB6F4BB7AB6AE8923391349FB7F479A1
6、ipx-188：magnet:?xt=urn:btih:ACE9F0A18DD19EF3943E1B9387CEC75FFB2D6964

年度最佳学生妹:
1、ssni-036 ：magnet:?xt=urn:btih:DB6843DA17B8DA14A0187E0FC0882A5230E38F15
2、ipx-177：magnet:?xt=urn:btih:CFAA95AD5504F0111968EFBEB2FFB25B80E8E33E
3、ssni-025：magnet:?x



"""