# 测试 CICE（Testing CICE）

本章主要介绍如何使用 CICE 脚本进行测试。具体测试内容取决于代码改动的性质。合并到 CICE Consortium 主分支前，改动须经审查，开发者应提供所做测试的摘要。CICE
默认提供一套基础测试，可作为起点。

测试脚本支持：通过 `--test` 运行单项测试或通过输入文件和 `--suite` 运行多个测试；使用随包提供或用户自定义的测试套件；用 `--bgen` 保存回归测试结果、用
`--bcmp` 与既有基线（baseline）比较逐位一致性（bit-for-bit）、用 `--bdir` 指定基线目录；用 `--diff` 比较两个测试；用 `--acct` 和
`--queue` 指定批处理账户及队列；并用 `--setup-only`、`--setup-build`、`--setup-build-run`、
`--setup-build-submit` 控制套件执行阶段。

## 单项测试（Individual Tests）

命令行示例：

```sh
./cice.setup --test smoke --mach conrad --env cray --set diag1,debug --testid myid
```

测试与案例相似，但附带额外的测试脚本；单项测试也可建立后手动修改。许多选项与[案例选项](ug_running.md)相同。`--test TESTNAME` 指测试类型，常见 `smoke`
或 `restart`，具体以 `cice.setup --help` 为准；它替代 `--case`。`--testid ID` 是每个 `--test` 和 `--suite`
都必须提供的用户标识，使案例和运行目录名唯一。`--tdir PATH` 指测试目录，默认当前目录。还可使用案例模式的 `--mach`、`--env`、`--set`、
`--ignore-user-set`、`--acct`、`--grid`、`--pes`。

回归与比较测试额外支持：

- `--bdir DIR`：基线结果顶层目录，配合 `--bgen`、`--bcmp`；默认来自机器环境文件的 `ICE_MACHINE_BASELINE`。
- `--bgen DIR`：在基线目录下创建指定子目录并保存当前测试结果。`DIR=default` 时脚本按 CICE 哈希及日期时间自动命名，便于追踪基线。
- `--bcmp DIR`：将当前结果与基线目录中该子目录的旧结果比较。`DIR=default` 时自动使用基线目录中最后一个目录，便于自动回归测试。
- `--diff LONG_TESTNAME`：与另一个已经完成、`testid` 相同的本地测试比较逐位一致性。与跨模型版本比较同一测试的 `--bcmp` 不同，它比较两个案例，
  例如不同块尺寸、区域分解或模型选项。`LONG_TESTNAME` 格式为 `[test]_[grid]_[pes]_[sets]`，脚本会自动补齐机器、环境和测试标识；见下文示例 6。

测试案例目录名始终为 `[machine]_[env]_[test]_[grid]_[pes]_[sets].[testid]`。脚本按字母顺序排列 `sets`，故
`--set debug,diag1` 和 `--set diag1,debug` 生成相同名称，末尾都是 `_debug_diag1`。

创建后，与一般案例一样进入目录构建、提交，并查看本地 `test_output`：

```sh
cd [test_case]
./cice.build
./cice.submit
cat test_output
```

测试定义在 `configuration/scripts/tests/`。`smoke` 按默认时长运行模型，可用 `--set` 改时长与选项，成功完成即通过。`restart` 先运行
10 天，在第 5 天和结束时写重启文件；再从第 5 天重启运行到第 10 天；两次都完成且第 10 天的两个重启文件逐位相同才通过。`decomp` 在给定配置下测试多种区域分解。最新信息以
`./cice.setup --help` 为准。添加新测试见[开发者测试指南](../developer_guide/dg_scripts.md#测试脚本)。

### 单项测试示例

1. 基础默认测试，指定测试、机器、环境和 `testid`：

   ```sh
   ./cice.setup --test smoke --mach wolf --env gnu --testid t00
   cd wolf_gnu_smoke_col_1x1.t00
   ./cice.build
   ./cice.submit
   cat test_output
   ```

2. 使用 `--set` 增加选项：

   ```sh
   ./cice.setup --test smoke --mach wolf --env gnu --set diag1,debug --testid t00
   cd wolf_gnu_smoke_col_1x1_debug_diag1.t00
   ./cice.build
   ./cice.submit
   cat test_output
   ```

3. 使用 `--bgen` 生成基线数据集：

   ```sh
   ./cice.setup --test smoke --mach wolf -env gnu --bgen cice.v01 --testid t00 --set diag1
   cd wolf_gnu_smoke_col_1x1_diag1.t00
   ./cice.build
   ./cice.submit
   cat test_output
   ```

4. 用 `--bcmp` 与既有基线比较。基线必须存在，且基本测试名称 `[machine]_[env]_[test]_[grid]_[pes]_[sets]` 完全相同：

   ```sh
   ./cice.setup --test smoke --mach wolf -env gnu --bcmp cice.v01 --testid t01 --set diag1
   cd wolf_gnu_smoke_col_1x1_diag1.t01
   ./cice.build
   ./cice.submit
   cat test_output
   ```

5. 同时生成新基线并与旧基线比较；旧基线须已存在：

   ```sh
   ./cice.setup --test smoke --mach wolf -env gnu --bgen cice.v02 --bcmp cice.v01 --testid t02 \
       --set diag1
   cd wolf_gnu_smoke_col_1x1_diag1.t02
   ./cice.build
   ./cice.submit
   cat test_output
   ```

6. 使用 `--diff` 比较两个本地测试，必须先运行参照测试，且两个 `testid` 相同。比较相对于当前案例目录进行；脚本在 `--diff` 参数前后补齐机器／环境及
   `testid`，结果写入 `test_output`：

   ```sh
   ./cice.setup --test smoke --mach wolf -env gnu --testid tx01 --set debug
   cd wolf_gnu_smoke_col_1x1_debug.tx01
   ./cice.build
   ./cice.submit
   cat test_output

   ./cice.setup --test smoke --mach wolf -env gnu --testid tx01 --diff smoke_col_1x1_debug
   cd wolf_gnu_smoke_col_1x1.tx01
   ./cice.build
   ./cice.submit
   cat test_output
   ```

### 专项测试案例

除通用框架中的测试外，还提供检验特定模型模块的专项测试。

#### `box2001`

`box2001` 对应 Hunke (2001) 的矩形网格盒模型测试。它在四周为陆地边界的 80×80 网格上运行 72 小时，关闭热力学。namelist 改动为：
`dxrect=16.e5` cm；`dyrect=16.e5` cm；`ktherm=-1`（关闭热力学）；`coriolis=constant`（`f=1.46e-4 s⁻¹`）；
`ice_data_type=box2001`（特殊初始海冰掩膜）；`ice_data_conc=p5`；`ice_data_dist=box2001`（特殊浓度初始化）；
`atm_data_type=box2001`（特殊大气和海洋强迫）。海洋应力按 Hunke (2001) 设置为以方形区域中心为圆心的环流；海冰厚度恒为 2 m，浓度沿 x 方向由 0
线性增至 1，沿 y 方向不变；无岛屿。

```sh
./cice.setup -m <machine> --test smoke -s box2001 --testid <test_id> --grid gbox80 --acct \
    <queue manager account>
```

#### `boxslotcyl`

`boxslotcyl` 对应 Zalesak (1979) 的开槽圆柱平流测试：四周陆地边界的 80×80 方形网格，运行 12 天，关闭热力学、脊化和动力学。参数：
`dxrect=10.e5` cm（10 km）、`dyrect=10.e5` cm、`ktherm=-1`、`kridge=-1`、`kdyn=-1`、
`ice_data_type=boxslotcyl`、`ice_data_conc=c1`、`ice_data_dist=uniform`。关闭动力学是因为直接施加恒定的环形速度场，
绕区域中心旋转一周需 $T=12$ 天：

$$
(u,v)=u_0\left(\frac{2y-L}{L},\frac{-2x+L}{L}\right),\qquad u_0=\frac{\pi L}{T}.
$$

这里 $L$ 为区域实际长度。初始开槽圆柱半径 $r=3L/10$，圆心 $(x,y)=(L/2,3L/4)$；径向槽宽 $L/6$、深 $5L/6$。时间步长为 1 小时，
在上述速度和网格尺寸下，Courant 数为 0.86。该测试可使用多个处理器。

```sh
./cice.setup -m <machine> --test smoke -s boxslotcyl --testid <test_id> --grid gbox80 --acct \
    <queue manager account> -p nxm
```

## 测试套件（Test Suites）

测试套件通过输入文件指定多个测试。运行 `cice.setup --suite` 时，脚本自动在本地 `testsuite.[testid]` 下建立、构建和提交所有测试：

```sh
./cice.setup --suite base_suite --mach wolf --env gnu --testid myid
cd testsuite.myid
./results.csh
```

与单项测试一样，必须提供任意字符串形式的 `--testid`。测试完成后在该目录执行 `results.csh` 查看结果。可用逗号分隔多个套件，如
`--suite base_suite,decomp_suite`；命令行 `-s debug` 会为所有测试添加此选项，且与套件文件冲突时命令行优先。多个套件按用户指定顺序运行，
重复测试仅建立和运行一次。

预定义套件的 `.ts` 文件位于 `configuration/scripts/tests/`：

- `quick_suite`：少量基础测试。
- `base_suite`：覆盖 CICE 大部分功能的较大测试集。
- `decomp_suite`：验证不同分解和处理单元数的结果逐位相同。
- `omp_suite`：验证 OpenMP 单线程与多线程结果逐位相同。
- `io_suite`：测试 binary、netcdf、pio 等 I/O；完整使用需要本地安装 PIO 并供构建系统访问。
- `perf_suite`：评估模型扩展性和性能。
- `reprosum_suite`：设 `bfbflag=reprosum` 时，检验不同分解和处理单元数的 CICE 日志逐位相同。
- `gridsys_suite`：测试 `grid_ice` 的 B、C、CD 网格配置。
- `prod_suite`：少量运行 5–10 模型年并含质量控制（QC）的测试，耗时和成本较高。
- `unittest_suite`：运行仓库中的单元测试。
- `travis_suite`：适于少量处理单元的简短套件，供 GitHub Actions CI 工作流使用。
- `first_suite`：与其他套件部分重叠，但先运行后续比较所需的关键基线测试，可缩短等待时间。

套件文件是空白字符分列的文本：第 1 列为测试名，第 2 列为网格，第 3 列为处理单元配置（PEs），第 4 列为 `--set`，第 5 列为 `--diff`；后两列可选。空行与以
`#` 开头的行忽略。例如：

```text
#Test    Grid PEs  Sets              Diff
smoke    col  1x1  diag1
smoke    col  1x1  diag1,run1year    smoke_col_1x1_diag1
smoke    col  1x1  debug,run1year
restart  col  1x1  debug
restart  col  1x1  diag1
restart  col  1x1  pondlvl
restart  col  1x1  pondtopo
```

`--suite` 参数是 `.ts` 文件名，可带路径；`cice.setup` 会在当前目录、`configuration/scripts/tests/` 或参数所给路径查找。
套件输入文件已指定许多参数，因此命令行仅接受：必需的 `--suite filename`、`--mach MACHINE`、`--testid ID`；强烈建议的
`--env ENVIRONMENT1,ENVIRONMENT2`；可选的 `--set`、`--acct`、`--tdir`、`--bdir`、`--bgen`、`--bcmp`。其中
`--bdir` 默认取机器环境文件的 `ICE_MACHINE_BASELINE`；`--bgen` 将结果复制到该目录下的指定子目录，`--bcmp` 与该目录下的旧结果比较，
二者建议使用。

套件还接受：`--report`（全部测试完成后将结果发送至结果页面，见“测试报告”）；`--coverage`（降低构建优化并通过 lcov 或 codecov 产生代码覆盖率诊断报告，
主要用于定期诊断，不建议一般运行使用）；`--setup-only`（仅建案例）；`--setup-build`（建案例并构建）；`--setup-build-run`（建案例、
构建并交互运行）；`--setup-build-submit`（建案例、构建并批量提交，默认）。

`cice.setup --suite` 会生成 `testsuite.[testid]/suite.submit`，用来构建及提交各测试。上述 `--setup-*` 选项改变
`cice.setup` 如何调用它；也可手动调用，通过环境变量 `SUITE_BUILD`、`SUITE_RUN`、`SUITE_SUBMIT` 控制。默认值分别是 `true`、
`false`、`true`，即构建并提交。手动调用时，只有全小写 `true` 才会开启相应功能，且 `SUITE_RUN` 与 `SUITE_SUBMIT` 不能同时为真。
结合命令行与环境变量，可灵活进行仅建立、建立并构建、重新提交、交互运行或重建后再提交。

`create_fails.csh` 可处理 `results.csh` 输出，生成仅含失败测试的 `fails.ts`；编辑后可用
`cice.setup --suite fails.ts ...` 重跑失败子集，提高开发效率。但最终代码版本仍应运行完整套件。合并到 Consortium 主分支的 PR 需报告测试结果，
见“测试报告”。使用 `--tdir` 时目录事先不能存在，脚本会创建并填入测试及辅助脚本，例如：

```sh
./cice.setup --suite base_suite --mach wolf --env gnu --testid myid --tdir \
    /scratch/$user/testsuite.myid
```

### 测试套件示例

下列各例在运行 `cice.setup` 后进入对应的 `testsuite.*` 目录，等待任务完成，再运行 `./results.csh`。

1. 基本套件，指定套件、机器、环境和测试标识：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray --testid v01a
   cd testsuite.v01a
   ./results.csh
   ```

2. 自定义测试目录，额外使用 `--tdir`：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray --testid v01a --tdir \
       /scratch/$user/ts.v01a
   cd /scratch/$user/ts.v01a
   ./results.csh
   ```

3. 多种环境同时测试；也可分别调用 `cice.setup`，那时建议使用不同 `testid`：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray,pgi,intel,gnu --testid v01a
   cd testsuite.v01a
   ./results.csh
   ```

4. 添加命令行预设 `--set diag1`。与套件中的预设冲突时，命令行优先：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env gnu --testid v01b --set diag1
   cd testsuite.v01b
   ./results.csh
   ```

5. 一次运行多个套件；重复测试只创建一次：

   ```sh
   ./cice.setup --suite base_suite,decomp_suite --mach conrad --env gnu --testid v01c
   cd testsuite.v01c
   ./results.csh
   ```

6. 用 `--bgen` 将基线保存在默认顶层目录的 `cice.v01a` 子目录：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray --testid v01a --bgen cice.v01a
   cd testsuite.v01a
   ./results.csh
   ```

7. 再用 `--bdir` 指定顶层目录，结果保存在 `/tmp/user/CICE_BASELINES/cice.v01a`：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray --testid v01a --bgen cice.v01a \
       --bdir /tmp/user/CICE_BASELINES
   cd testsuite.v01a
   ./results.csh
   ```

8. `--bgen default` 让脚本自动以哈希和日期生成目录名：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray --testid v01a --bgen default
   cd testsuite.v01a
   ./results.csh
   ```

9. `--bcmp` 与 `cice.v01a` 基线逐位比较，是许多（并非所有）PR 合入前的重要步骤；还可组合 `--bdir`、`--bgen`：

   ```sh
   ./cice.setup --suite base_suite --mach conrad --env cray --testid v02a --bcmp cice.v01a
   cd testsuite.v02a
   ./results.csh
   ```

10. `default` 对 `--bgen` 表示按哈希和日期建立新目录，对 `--bcmp` 表示使用基线顶层目录中最新的目录；这样生成目录自动携带哈希，比较报告也记录所比目录，
    便于自动化。定期构建示例：

    ```sh
    set mydate = `date -u "+%Y%m%d"`
    git clone https://github.com/myfork/cice cice.$mydate --recursive
    cd cice.$mydate
    ./cice.setup --suite base_suite --mach conrad --env cray,gnu,intel,pgi --testid $mydate \
        --bcmp default --bgen default --bdir /tmp/work/user/CICE_BASELINES_MAIN
    ```

    每次运行都会生成新基线并与旧结果比较，无须更改参数。

11. 加 `-s buildincremental` 后可复用套件，修改源码时只重编译变化文件再重跑：

    ```sh
    ./cice.setup --suite base_suite --mach conrad --env intel --testid v01b --set \
        buildincremental
    cd testsuite.v01b
    ./results.csh
    # 修改代码后
    ./suite.submit
    ./results.csh
    ```

12. 自定义套件文件有五列：测试、网格、PEs、可选预设、可选的 `diff` 对象。`diff` 所指测试应尽可能排在前面，尽管仍不能绝对保证完成顺序。标准回归选项均可使用：

    ```text
    # mysuite
    smoke    col  1x1  diag1,debug
    restart  col  1x1
    restart  col  1x1  diag1,debug    restart_col_1x1
    restart  col  1x1  mynewoption,diag1,debug
    ```

    ```sh
    ./cice.setup --suite mysuite --mach conrad --env cray --testid v01a --bgen default
    cd testsuite.v01a
    ./results.csh
    ```

13. 先建立套件，再手动构建、提交；`setenv` 是 csh/tcsh 语法，Bash 使用 `SUITE_BUILD=true` 等语法：

    ```csh
    ./cice.setup --suite quick_suite,base_suite --mach conrad --env cray,gnu --testid v01a \
        --setup-only
    cd testsuite.v01a
    setenv SUITE_BUILD true
    setenv SUITE_RUN false
    setenv SUITE_SUBMIT false
    ./suite.submit
    setenv SUITE_BUILD false
    setenv SUITE_RUN false
    setenv SUITE_SUBMIT true
    ./suite.submit
    ./results.csh
    ```

## 单元测试（Unit Testing）

CICE 脚本支持单元测试。它们通过 `cicecore/drivers/unittest/` 中独立的顶层驱动明确测试模型功能，也有辅助脚本。构建和运行方式与标准模型相似：建立案例，
输出保存到案例 `logs/`；也可作为测试套件的一部分运行，通过日志文件的简单 diff 与旧输出比较。

日历单元测试作为案例运行：

```bash
./cice.setup -m onyx -e intel --case calchk01 -p 1x1 -s calchk
cd calchk01
./cice.build
./cice.submit
```

作为单项测试运行：

```bash
./cice.setup -m onyx -e intel --test unittest -p 1x1 --testid cc01 -s calchk --bgen cice.cc01
cd onyx_intel_unittest_gx3_1x1_calchk.cc01/
./cice.build
./cice.submit
```

新增单元测试时，在 `cicecore/driver/unittest/` 加以测试名命名的驱动目录；在 `configuration/scripts/options/` 为新名称创建相应
`set_nml` 或 `set_env` 文件，其中 `ICE_DRVOPT`、`ICE_TARGET` 必须在 `set_env` 定义；最后在
`configuration/scripts/Makefile` 添加目标。可参考 `calchk` 和 `helloworld`。运行结束时日志应写
`COMPLETED SUCCESSFULLY` 表示运行完成、`TEST COMPLETED SUCCESSFULLY` 表示所有单元测试通过。回归测试对比单元测试日志；在待对比输出开始处写
`RunningUnitTest`。测试脚本会查询这些字符串并据此报告结果。

现有测试包括：`bcstchk` 测 `ice_broadcast.F90` 的方法，不依赖 CICE 网格，可分别以串行和 MPI 配置检验；`calchk` 检验 100,000
年的日历，不依赖 CICE 初始化；`gridavgchk` 检验 `grid_average_X2Y`；`halochk` 检验 `haloUpdate`；`helloworld` 不使用
CICE 基础设施，演示在 Makefile 直接指定目标文件；`optargs` 检查调用树传递可选参数时 optional 属性是否保持；`opticep` 关闭传入 Icepack
的可选参数，仅适用于部分 CICE/Icepack 案例；`sumchk` 检验 `ice_global_reductions.F90`，需先通过 `CICE_InitMod.F90`
初始化网格和分解，再执行一组验证。

## 测试报告（Test Reporting）

脚本可将结果发布到
[CICE Consortium Test-Results Wiki](https://github.com/CICE-Consortium/Test-Results/wiki)，可能需要该
Wiki 的写权限，可联系 Consortium。代码通过 PR 合入主分支需要开发者证明相关测试通过，可将完整结果发到 Wiki，或将摘要复制到 PR 评论。套件完成后在其目录运行：

```sh
./cice.setup --suite base_suite --mach conrad --env cray --testid v01a
cd testsuite.v01a
# 等待运行结束
./results.csh
./report_results.csh
```

`report_results.csh` 默认会自动运行 `results.csh`；建议发布前先手动运行以核对。`report_results.csh -n` 可关闭自动调用。
也可在建立套件时加 `--report`：

```sh
./cice.setup --suite base_suite --mach conrad --env cray --testid v01a --report
```

这样会建立、构建、提交测试，等待全部完成，再运行结果与报告脚本。

## 代码覆盖率测试（Code Coverage Testing）

`cice.setup --coverage` 打开特殊编译标志、降低优化并调用 `gcov`；完成后可用 `lcov` 或 `codecov` 分析。当前仅在 GNU 编译器及少数修改过
Macros 的系统上可用。调用后脚本将工作区复制为类似 `cice_lcov_yymmdd-hhmmss` 的新工作区，稍微修改源码以改善覆盖率统计，并在其中运行完整覆盖率套件。

目前会自动运行套件目录中的 `report_lcov.csh` 进行 lcov 分析，结果见 [CICE lcov 网站](https://apcraig.github.io)。
使用者须有相应仓库写权限。lcov 应在完整的多个套件组合上运行，测试完成后处理数据可能还需数小时。例如：

```sh
./cice.setup --suite \
    first_suite,base_suite,travis_suite,decomp_suite,reprosum_suite,io_suite,quick_suite \
    --mach cheyenne --env gnu --testid cc01 --coverage
```

也可在套件目录手动运行 `report_codecov.csh`，但该方法仍有若干问题，通常不建议使用。端到端的 codecov 脚本在
`configuration/scripts/tests/cice_test_codecov.csh`；其分析与 lcov 大体相同，网页查看体验更好。覆盖率属于特殊诊断测试，
不代替标准模型测试，主要用于定期评估测试覆盖范围。

## 代码验证测试：非逐位一致验证

CICE 动力核心（dycore）和创新功能的一项核心原则是，除过时组件外，已有配置的物理过程和生物地球化学结果不应改变。修改现有 Consortium 代码应限于修复可证实的数值、
科学误差或缺陷，或引入新科学所必需的改动。新物理过程或生物地球化学过程关闭时，不应改变模型结果，此时 CICEcore 和 CICE 应与相同 namelist 配置的旧模拟逐位一致。
地球系统模型常有这一要求，但新增功能可能必须修改旧代码，实际无法始终做到；不同平台和编译器也可能影响一致性。因此，除逐位测试外，还开发了科学测试工具。它们利用模拟海冰厚度的统计性质，
检验“新增动力核心和 CICE 功能未显著改变既有配置的模拟冰体积”这一零假设（null hypothesis）。下述工具使用标准 CICE 大气强迫的五年 gx-1 模拟输出；科学依据见
Hunke 等（2018），本节遵循 Roberts 等（2018）。

### 两阶段配对厚度检验（Two-Stage Paired Thickness Test）

第一项质量控制（QC）在每个网格点检验 $H_0:\mu_d=0$，即应相同的配对模拟 $a$、$b$ 的平均厚度差为零。对 gx-1 网格每格的 $n$ 对厚度样本 $h_{ai}$、
$h_{bi}$，用 $\bar h_d=n^{-1}\sum_{i=1}^{n}(h_{ai}-h_{bi})$ 估计 $\mu_d$。按 Wilks（2006），期望均值为零的 $t$
统计量为：

$$
t=\frac{\bar h_d}{\sigma_d/\sqrt{n_{eff}}},\qquad
\sigma_d^2=\frac{1}{n-1}\sum_{i=1}^{n}(h_{di}-\bar h_d)^2,\quad h_{di}=h_{ai}-h_{bi}.
$$

有效样本数（effective sample size）和一阶滞后自相关（lag-1 autocorrelation）为：

$$
n_{eff}=n\frac{1-r_1}{1+r_1},
$$

$$
r_1=\frac{\sum_{i=1}^{n-1}(h_{di}-\bar h_{d1:n-1})(h_{d,i+1}-\bar h_{d2:n})}{\sqrt{\sum_{i=1}
^{n-1}(h_{di}-\bar h_{d1:n-1})^2\sum_{i=2}^{n}(h_{di}-\bar h_{d2:n})^2}}.
$$

其中 $\bar h_{d1:n-1}$、$\bar h_{d2:n}$ 分别去掉最后和第一个样本：

$$
\bar h_{d1:n-1}=\frac{1}{n-1}\sum_{i=1}^{n-1}h_{di},\quad
\bar h_{d2:n}=\frac{1}{n-1}\sum_{i=2}^{n}h_{di},\quad
\bar h_d=\frac{1}{n}\sum_{i=1}^{n}h_{di}.
$$

按 Zwiers 等（1995），将 $n_{eff}$ 限制在 $[2,n]$。该公式假设海冰厚度近似一阶自回归过程（AR(1)）；五年厚度日样本的谱密度可支持此假设。
海冰速度受惯性和潮汐周期影响，不适合 AR(1)；海冰浓度配对检验可能对漂移不够敏感。因此厚度最适合 Consortium 的 QC，尤其适于均值检验。

均值 $t$ 检验的自由度为 $N=n_{eff}-1$。当 $n_{eff}<30$ 时检验可能过于保守，错误接受零假设；五年模拟某些 gx-1 区域可出现 $r_1>0.99$。
若第一阶段接受 $H_0$ 且 $2\le n_{eff}<30$，继续使用 Zwiers 等的“查表检验”（Table Lookup Test）。它按 $r_1$ 和显著性水平
$\alpha$ 查临界值 $|t|<t_{crit}(1-\alpha/2,N)$，使用常规 $t=\bar h_d\sqrt n/\sigma_d$ 和 $N=n-1$，但临界值通过
Monte Carlo 方法生成。五年 QC 的 $N=1824$、双侧 80% 置信区间（$\alpha=0.2$），以限制错误接受零假设的第二类错误（Type II error）。

| $r_1$ | -0.05 | 0.0 | 0.2 | 0.4 | 0.5 | 0.6 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| $t_{crit}$ | 1.32 | 1.32 | 1.54 | 2.02 | 2.29 | 2.46 |

| $r_1$ | 0.7 | 0.8 | 0.9 | 0.95 | 0.97 | 0.99 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| $t_{crit}$ | 3.17 | 3.99 | 5.59 | 8.44 | 10.85 | 20.44 |

### 二次技巧验证检验（Quadratic Skill Validation Test）

除均值检验，还使用改自 Taylor（2001）的技巧指标（skill metric）检查配对模拟是否高度相关且方差相近。Taylor 图的一般技巧分数为：

$$
S_m=\frac{4(1+R)^m}{(\hat\sigma_f+1/\hat\sigma_f)^2(1+R_0)^m}.
$$

$m=1$ 偏重方差，$m=4$ 偏重相关性；QC 选 $m=2$ 平衡两者。$\hat\sigma_f=\sigma_b/\sigma_a$ 为模拟 $b$ 与对照模拟 $a$
的标准差之比；$R$ 是成对厚度的相关系数，$R_0$ 是可能的最大相关性。逐位重现时 $R_0=1$，因此：

$$
S=\left[\frac{(1+R)\sigma_a\sigma_b}{\sigma_a^2+\sigma_b^2}\right]^2.
$$

$S$ 在 0 与 1 之间。分别对 gx-1 网格南、北半球的日厚度按面积加权。五年模拟 $a$ 的半球平均厚度为：

$$
\bar h_a=\frac1n\sum_{i=1}^{n}\sum_{j=1}^{J}W_jh_{a,i,j},\qquad W_j=\frac{A_j}{\sum_{j=1}^{J}
A_j}.
$$

$i$ 是时间样本，$j$ 是网格点，$n$ 通常为 1825，$J$ 是网格点总数，$A_j$ 为面积；权重应用于任一模拟至少一个非零厚度的网格点。模拟 $b$ 同理。加权方差及相关系数为：

$$
\sigma_a^2=\frac{\hat J}{n\hat J-1}\sum_{i=1}^{n}\sum_{j=1}^{J}W_j(h_{a,i,j}-\bar h_a)^2,
\qquad R=\frac{\mathrm{cov}(h_a,h_b)}{\sigma_a\sigma_b},
$$

$$
\mathrm{cov}(h_a,h_b)=\frac{\hat J}{n\hat J-1}\sum_{i=1}^{n}\sum_{j=1}^{J}W_j(h_{a,i,j}-
\bar h_a)(h_{b,i,j}-\bar h_b).
$$

$\hat J$ 是非零权重数；$\sigma_b$ 同理。南北半球分别计算 $S$，均须超过默认临界值 $S_{crit}=0.99$ 才通过。实际示例及两阶段测试见 Hunke
等（2018）。


### 代码验证测试步骤（Code Validation Testing Procedure）

CICE 质量控制测试由 `configuration/scripts/tests/QC/cice.t-test.py` 完成。需要 Python 2.7 或更新版本、netcdf 与
numpy Python 包；matplotlib 和 basemap 为可选。应选择能触发代码修改的配置（如 namelist 选项），必要时测试多个配置；有疑问可咨询
Consortium。为生成所需文件，调用 `cice.setup` 时加 `--set qc`，这会在五年模拟中写出逐日、未平均的历史文件。

可用 pip 安装所需包，或建立 `qctest` conda 环境：

```bash
pip install --user netCDF4
pip install --user numpy
pip install --user matplotlib
pip install --user cartopy

conda env create -f configuration/scripts/tests/qctest.yml
conda activate qctest
```

先用原版模型建立基线模拟，再用改动后的模型建立扰动模拟，两者都加 `--set qc` 和其他所需设置。随后从 `configuration/scripts/tests/QC/`
目录运行脚本，因为它还需要该目录的其他文件：

```bash
cd configuration/scripts/tests/QC
./cice.t-test.py /path/to/baseline/history /path/to/test/history
```

正常输出会报告 1825 个文件、两阶段测试通过、南北半球的二次技巧测试通过，并显示 `Quality Control Test PASSED`。退出码 `echo $?` 为 0 表示通过，
为 1 表示失败。脚本需在内存中保存覆盖 1825 个时间步的多个二维场，总共数 GB；内存不足时改用批处理资源或大内存节点。它还会尝试绘制基线与测试模拟的平均厚度图；若两阶段测试失败，
则绘制失败网格单元分布图。完整选项见 `python cice.t-test.py -h`。

### 端到端测试步骤（End-To-End Testing Procedure）

可能导致非逐位结果的代码改动，应先做回归测试。若系统尚无基线，先从基线代码生成；若要替换既有基线，需先删除 `${ICE_BASELINE}/cice.my.baseline`。
再用新代码运行套件并与该基线比较，查看失败测试和相关 namelist 选项：

```bash
# 在基线版本源码中建立结果
./cice.setup -m onyx -e intel --suite base_suite --testid base0 --bgen cice.my.baseline
cd testsuite.base0
./results.csh

# 在新版本源码中与基线比较
./cice.setup -m onyx -e intel --suite base_suite --testid test0 --bcmp cice.my.baseline
cd testsuite.test0
./results.csh
```

若回归比较失败，可继续做 QC。分别在基线与更新后的工作区建立相同的 gx1、44×1、五年 `qc` 案例，按已识别的选项修改 `ice_in`，构建并提交：

```bash
# 基线工作区
./cice.setup -m onyx -e intel --test smoke -g gx1 -p 44x1 --testid qc_base -s qc,medium
cd onyx_intel_smoke_gx1_44x1_medium_qc.qc_base
# 修改 ice_in，启用需要验证的 namelist 选项
./cice.build
./cice.submit

# 更新后的工作区
./cice.setup -m onyx -e intel --test smoke -g gx1 -p 44x1 --testid qc_test -s qc,medium
cd onyx_intel_smoke_gx1_44x1_medium_qc.qc_test
# 按基线相同方式修改 ice_in
./cice.build
./cice.submit
```

等待运行结束，在更新后的工作区比较两组输出：

```bash
cp configuration/scripts/tests/QC/cice.t-test.py .
./cice.t-test.py /p/work/turner/CICE_RUNS/onyx_intel_smoke_gx1_44x1_medium_qc.qc_base \
                 /p/work/turner/CICE_RUNS/onyx_intel_smoke_gx1_44x1_medium_qc.qc_test
```

示例报告依次为 `Number of files: 1825`、`Two-Stage Test Passed`、南北半球的 `Quadratic Skill Test Passed` 和
`Quality Control Test PASSED`。

[英文原文](../../source/user_guide/ug_testing.rst)

