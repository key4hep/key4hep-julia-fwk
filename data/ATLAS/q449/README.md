# q449

Standard reconstruction test job

- release: Athena/25.0.4
- build: x86_64-el9-gcc13-opt
- platform: AMD Ryzen 7 5700G with Radeon Graphics (16) @ 3.800GHz
- Command:
  ```sh
  ATHENA_CORE_NUMBER=8 Reco_tf.py --multithreaded --AMIConfig q449 --preExec "ConfigFlags.PerfMon.doFullMonMT=True" --postExec "from AthenaConfiguration.ComponentFactory import CompFactory;from GaudiHive.GaudiHiveConf import PrecedenceSvc; cfg.addService(CompFactory.PrecedenceSvc(DumpPrecedenceRules=True))"
  ```
