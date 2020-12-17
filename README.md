# MIPS_CPU

用Verilog编写一个MIPS指令集，32位5级流水线的CPU，代码中有详细的注释以及我思考的过程，可能会有错误的地方，请见谅

参考《自己动手写CPU》，目前已实现基础的58条指令，其中包括逻辑、移位、移动、算术、转移、加载存储以及空指令等，后续大概不会再更新了

# 运行环境

## 软件

运行环境：Vivado 2016

指令生成：在Ubuntu系统下生成，因为书中的工具不能用，所以参考文章[如何获取MIPS汇编对应的机器码](https://blog.csdn.net/weixin_42972730/article/details/105640023)

# 项目运行

下载文件之后，直接用vivado打开就可以了

# 项目架构图

![image-20201217161841313](https://gitee.com/hzm_pwj/FigureBed/raw/master/giteeImg/20201217161841.png)

