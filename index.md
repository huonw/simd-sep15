% SIMD in Rust

Huon Wilson

<small>Mozilla Research & University of Sydney</small>

<br>

[<small>huonw.github.io/simd-aug15</small>](http://huonw.github.io/simd-aug15)

# SIMD?

**S**ingle **I**nstruction **M**ultiple **D**ata: Do many number
  things at once.

![](vector.png)

# Important, ubiquitous

Non-embedded devices have SIMD:

- **x86**/<strong>x86-64</strong>: SSE2, AVX2, AVX512 (etc.)
- **ARM**/<strong>AArch64</strong>: NEON, VFP
- **PowerPC**: AltiVec
- **MIPS**: MSA (MDMX, MIPS-3D)
- (**SPARC**: Visual Instruction Set)

# RFC #1199

[<img src="rfc.png" class="shadow"></img>](https://github.com/rust-lang/rfcs/pull/1199)

# PR #27169 (et al.)

[<img src="pr.png" class="shadow"></img>](https://github.com/rust-lang/rust/pull/27169)

# `github.com/huonw/simd`

[<img src="crate.png" class="shadow"></img>](https://github.com/huonw/simd)

# Publicity

[<img src="blog.png" class="shadow"></img>](http://huonw.github.io/blog/2015/08/simd-in-rust/)

<img src="ga.png" class="shadow"></img>

# Mandelbrot

![](mandel.png)

# <img src=mandel.png class='header-image'>

```rust
fn mandelbrot(c_x: f32, c_y: f32,
              max_iter: u32) -> u32
{
    let mut x = c_x;
    let mut y = c_y;

    let mut count = 0;
    while count < max_iter {
        let xy = x * y;
        let xx = x * x;
        let yy = y * y;
        let sum = xx + yy;

        if sum > 4.0 { break }

        count += 1;

        x = xx - yy + c_x;
        y = xy + xy + c_y;
    }
    count
}
```

# <img src=mandel.png class='header-image'>&times;4

```rust
fn mandelbrot(c_x: f32x4, c_y: f32x4,
              max_iter: u32) -> u32x4
{
    let mut x = c_x;
    let mut y = c_y;

    let mut count = u32x4::splat(0);
    for _ in 0..max_iter as usize {
        let xy = x * y;
        let xx = x * x;
        let yy = y * y;
        let sum = xx + yy;
        let mask = sum.lt(f32x4::splat(4.0));
        if !mask.any() { break }

        count = count + mask.to_i().select(u32x4::splat(1),
                                           u32x4::splat(0));
        x = xx - yy + c_x;
        y = xy + xy + c_y;
    }
    count
}
```


# Benchmarks...

2.4&times; faster, on average.

![](chart-x86-64.png)

# Benchmarks... everywhere

2.1&times; faster, on average.

![](chart-aarch64.png)

# Benchmarks... everywhere

2.4&times; faster, on average.

![](chart-arm.png)

# <img src=mandel.png class='header-image'>&times;4: zero overhead

<table class="compare">
<tbody>
<tr><td>
<pre><code>for _ in 0..max_iter as usize {
<div class="group-a">    let xy = x * y;
    let xx = x * x;
    let yy = y * y;</div><div class="group-b">    let sum = xx + yy;</div><div class="group-c">    let mask = sum.lt(f32x4::splat(4.0));</div><div class="group-d">    if !mask.any() {

        break }</div>

<div class="group-e">    count = count + mask.to_i().select(u32x4::splat(1),
                                       u32x4::splat(0));</div><div class="group-f">    x = xx - yy + c_x;</div>

<div class="group-f">    y = xy + xy + c_y;</div>

}</pre></code>
</td><td>
<pre><code>.LBB1_1:
<div class="group-a">    fmul    v7.4s, v5.4s, v5.4s
    fmul    v16.4s, v6.4s, v6.4s</div>
<div class="group-b">    fadd    v17.4s, v16.4s, v7.4s</div><div class="group-c">    fcmgt   v17.4s, v3.4s, v17.4s</div><div class="group-d">    umaxv   s18, v17.4s
    fmov    w9, s18
    cbz     w9, .LBB1_3</div><div class="group-a">    fmul    v6.4s, v6.4s, v5.4s</div>    add     x8, x8, #1
<div class="group-e">    and     v5.16b, v17.16b, v4.16b</div>
<div class="group-f">    fsub    v7.4s, v7.4s, v16.4s</div><div class="group-e">    add     v2.4s, v5.4s, v2.4s</div><div class="group-f">    fadd    v5.4s, v7.4s, v0.4s
    fadd    v6.4s, v6.4s, v6.4s
    fadd    v6.4s, v6.4s, v1.4s</div>    cmp     x8, #100
    b.lo    .LBB1_1</code></pre>
</td>
</tr>
<tbody>
</table>

# Future

- More platforms
- More comprehensive support in `simd`
- More libraries
- Dynamic SIMD feature dispatch (choose between `foo_avx`,
  `foo_sse41`, `foo_sse2`, etc.)
