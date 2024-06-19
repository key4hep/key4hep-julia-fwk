# Examples

Relevant as of Dagger 0.18.8

All examples are to be launched from the root folder (Dagger_0.18.8)

## Logging 

This folder contains examples related to logging mechanisms in Dagger.

## Auxiliary

Mock tasks definitions are contained there.

## Killing_procs.jl

Killing worker processes is essential for interactive work, so the relevant examples are shown here. However, they also demonstrate the related problems.

## Parallel_simple_DAGs_scheduling.jl

Multiple simple graphs scheduled using the old Dagger API. Their results are fetched and printed. To achieve parallelism with a scheduler, 4 workers are added (arbitrary number). In the end, all workers are removed and Julia exits. Alternatively, the effect of parallel execution may be achieved by launching the Julia with a few threads (5 here):

 ```console
> cd DAGGER_0.18.8
> julia --project=. -t5
julia> include("./examples/parallel_simple_DAGs_scheduling.jl")
```

## Parallel_complex_DAGs_scheduling.jl

This file contains the example of scheduling complex DAGs. First, the graphs are parsed, logging parsing results to the dedicated files (for further verification, if needed). Then, each graph is scheduled, its results are fetched and printed. Finally, logs are saved via special function (see Logging folder for the details) and converted to a graph image. Alternatively, you can use Dagger web dashboard (see the comments in the code).

Additionally, the parallel execution is achieved via adding worker processes or using multithreading, similar to the parallel_simple_DAGs_scheduling.jl example. There are three images contained in the `examples_results` folder: all of them are the visualizations of DAG in the scheduler, but one was obtained utilizing 12 worker processes, for another the total of 13 threads were used and the last one was executed without parallelism (no worker processes, 1 thread). Note that different node colors seem to denote different processors, which execute tasks of these nodes. Therefore, the image corresponding to no parallelism is in the single color, but the other ones depict many colors. Easy to notice that with many workers the scheme is quite stable - Dagger satisfies dependencies for the task and executes it on the same processor. Meanwhile, with multithreading the behaviour looks chaotic. That can be explained by the fact that moving data across the different workers may be considered as a costly operation in Dagger, so the tasks tend to be scheduled on the process already containing it. 