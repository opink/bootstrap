use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};
use std::sync::atomic::{AtomicI32, Ordering};

use std::mem;

const NUM: usize = 8;


// #[repr(align(32))]
// struct Counter {
//     pad: [i32; 8],  // 填充
//     value: AtomicI32,
// }

struct Counter { // padding to 64B fetch cache line
    pad: [i32; 15],  // 填充
    value: AtomicI32,
}

impl Counter {
    fn new() -> Counter {
        Counter {
            pad: [0; 15],
            value: AtomicI32::new(0),
        }
    }

    fn inc_count(&self) {
        self.value.fetch_add(1, Ordering::SeqCst);
    }

    fn read_count(&self) -> i32 {
        self.value.load(Ordering::SeqCst)
    }
}

fn run(counter: Arc<Counter>) {
    for _ in 0..10_000_000 {
        counter.inc_count();
    }
}

fn main() {
    let counters: Vec<Arc<Counter>> = (0..NUM).map(|_| Arc::new(Counter::new())).collect();
    let mut handles = vec![];

    let time1 = Instant::now();

    for counter in &counters {
        let counter_clone = Arc::clone(counter);
        handles.push(thread::spawn(move || {
            run(counter_clone);
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    let time2 = Instant::now();
    let total_count: i32 = counters.iter().map(|counter| counter.read_count()).sum();
    let time_diff = time2.duration_since(time1);
    let time_ms = time_diff.as_secs_f64() * 1000.0;

    println!("count={}, time={}ms", total_count, time_ms);

    println!("size = {}", mem::size_of::<Counter>());
}
