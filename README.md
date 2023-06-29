# bootstrap
统计小公举

TODO
1. fisher-yates shuffle 算法，有放回等概率抽样
2. 提前准备好 重抽样次数 X 重抽样循环数 的随机数集合，在循环中用迭代器加速采样

## Rust编译指令
1. Win中 先使用`set RUSTFLAGS=-C target-cpu=native` ，再编译`cargo build --release`。如果你并不在意你的二进制程序代码在更老（或其他类型的）处理器上的兼容性，你可以告诉编译器生成指定的 特定 CPU 架构 上的，最新（并且可能最快）的指令。
2. Cargo.toml文件中加入，如下编译选项也可加快运行速度。
  ```python
   [profile.release]
    codegen-units = 1 
    lto = true 
  ```
