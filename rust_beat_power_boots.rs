// the fastest one , singlethread powerN=10, takes 900ms , faster than Julia

use nanorand::{Rng, WyRand};
use rayon::prelude::*;
use std::time::Instant;

fn fill_array<const N: usize>(_size: usize, ones: usize) -> [f64; N] {
    let mut data = [0.0; N];
    (0..ones).for_each(|i| {
        data[i] = 1.0;
    });
    data
}

fn bootstrap_sampling(
    data: &[f64],
    s_size: usize,
    e_size: usize,
    rng: &mut WyRand,
    sample: &mut [f64],
) {
    (s_size..e_size).for_each(|i| unsafe {
        let item = *data.get_unchecked(rng.generate_range(0..data.len()));
        sample[i] = item;
    })
}

fn shuffle<T>(data: &mut [T], rng: &mut WyRand) {
    let len = data.len();
    (0..len).for_each(|i| {
        let j = rng.generate_range(i..len);
        data.swap(i, j);
    })
}

fn perm_fun(l: &mut [f64], n_a: usize, n_b: usize, perm_n: usize) -> Vec<f64> {
    let mut ret = vec![0.0; perm_n];
    let mut rng = WyRand::new();
    (0..perm_n).for_each(|ret_i| {
        shuffle(l, &mut rng);

        // 对半分比下面使用索引的形式快一点
        let (al, bl) = l.split_at(n_a);
        let diff = (al.iter().sum::<f64>() / n_a as f64) - (bl.iter().sum::<f64>() / n_b as f64);

        // let diff = (l[0..n_a].iter().sum::<f64>() / n_a as f64)
        //     - (l[n_a..].iter().sum::<f64>() / n_b as f64);

        ret[ret_i] = diff.abs();
    });
    ret
}

fn bootstrap_n(
    p0: &[f64],
    p1: &[f64],
    start_n: usize,
    end_n: usize,
    step: usize,
    alpha: f64,
    power_n: usize,
    perm_n: usize,
    effect_size: f64,
) -> Vec<(usize, f64)> {
    let mut searched_power = vec![];
    let start = Instant::now();
    for sample_size in (start_n..end_n).step_by(step) {
        let mut beta = vec![0.0; power_n];

        beta.iter_mut().for_each(|i| {
            // 使用单线程 取消注释该行
            // beta.par_iter_mut().for_each(|i| {
            // 使用rayon多线程
            let mut sample = vec![0.0; 2 * sample_size];
            let mut rng = WyRand::new();
            bootstrap_sampling(p0, 0, sample_size, &mut rng, &mut sample);
            bootstrap_sampling(p1, sample_size, 2 * sample_size, &mut rng, &mut sample);
            assert!(2 * sample_size == sample.len());
            let perm_diffs = perm_fun(&mut sample[..], sample_size, sample_size, perm_n);
            let count = perm_diffs.iter().filter(|&&d| d > effect_size).count();
            *i = count as f64 / perm_diffs.len() as f64;
        });

        let power_i = beta.iter().filter(|&&b| b < alpha).count() as f64 / power_n as f64;
        searched_power.push((sample_size * 2, power_i));
    }
    let duration = start.elapsed();
    println!("Time elapsed is: {:?}", duration);
    searched_power
}

fn main() {
    const P_SIZE: usize = 100;
    // const ABS_DIFFER: f64 = 0.02;
    let p0 = fill_array::<P_SIZE>(P_SIZE, 4);
    let p1 = fill_array::<P_SIZE>(P_SIZE, 9);
    let effect_size = (p0.iter().sum::<f64>() - p1.iter().sum::<f64>()) / P_SIZE as f64;
    let power = bootstrap_n(
        &p0,
        &p1,
        1600,
        1601,
        200,
        0.05,
        10,
        10000,
        effect_size.abs(),
    );
    for (sample_size, power_i) in power {
        if power_i > 0.9 {
            println!(
                "当样本量为{}时，置换检验的p值为显著性的概率POWER为{}",
                sample_size, power_i
            );
        } else {
            println!("当样本量为{}时，POWER={}", sample_size, power_i);
        }
    }
}
