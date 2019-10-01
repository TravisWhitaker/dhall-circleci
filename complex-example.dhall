let types = ./Schema.dhall

let someDockerImage =
      { dockerImage = "alpine"
      , dockerReachableName = Some "localhost"
      , dockerEntryPoint = [ "someProg", "someOtherProg" ]
      , dockerCommand = [ "someCmd", "--someFlag" ]
      , dockerUser = Some "root"
      , dockerEnv = [ { envVarName = "MICRO", envVarVal = "soft" } ]
      , dockerLoginAuth =
          Some { authUsername = "me", authPassword = "don'tdothis" }
      , dockerAWSAuth = None types.DockerAWSAuth
      }

let someOtherDockerImage =
      { dockerImage = "debian"
      , dockerReachableName = Some "10.0.0.1"
      , dockerEntryPoint = [ "someProg", "someOtherProg" ]
      , dockerCommand = [ "someCmd", "--someFlag" ]
      , dockerUser = Some "deb"
      , dockerEnv = [ { envVarName = "ARCH", envVarVal = "intel" } ]
      , dockerLoginAuth = None types.DockerLoginAuth
      , dockerAWSAuth = Some { awsAccessKey = "secrets", awsSecretKey = "eggs" }
      }

let plainNixDocker =
      types.ExecConfig.Docker
        [ { dockerImage = "nixos/nix:2.2.1"
          , dockerReachableName = None Text
          , dockerEntryPoint = [] : List Text
          , dockerCommand = [] : List Text
          , dockerUser = None Text
          , dockerEnv = [] : List types.EnvVar
          , dockerLoginAuth = None types.DockerLoginAuth
          , dockerAWSAuth = None types.DockerAWSAuth
          }
        ]

let someMachineImage =
      { machineImage = "circleci/classic:latest", machineLayerCaching = False }

let someMacOSImage = { macOSXCode = "10.0" }

let execs =
      [ { execName = "someDockerExecutor"
        , execResourceClass = Some types.ResourceClass.Small
        , execShell = Some "zsh"
        , execWD = Some "/somewhere"
        , execEnv = [ { envVarName = "FOO", envVarVal = "bar" } ]
        , execConfig =
            types.ExecConfig.Docker [ someDockerImage, someOtherDockerImage ]
        }
      , { execName = "someMachineExecutor"
        , execResourceClass = Some types.ResourceClass.Medium
        , execShell = Some "csh"
        , execWD = Some "/somewhere"
        , execEnv = [] : List types.EnvVar
        , execConfig = types.ExecConfig.Machine someMachineImage
        }
      , { execName = "someMacOSExecutor"
        , execResourceClass = Some types.ResourceClass.Large
        , execShell = Some "bash"
        , execWD = Some "/Users/jobs"
        , execEnv = [] : List types.EnvVar
        , execConfig = types.ExecConfig.MacOS someMacOSImage
        }
      ]

let buildStep =
      types.Step.Run { stepName = "build", stepCommand = "./do-the-build.sh" }

let buildLinuxJob =
      { jobName = "linux-build"
      , jobExec = types.JobExecConfig.NamedExec "someDockerExecutor"
      , jobSteps =
          [ types.Step.Run
              { stepName = "prepare"
              , stepCommand =
                  ''
                  ./do/something
                  ./do --something ./else
                  some --other --preparation
                  ''
              }
          , types.Step.Checkout
          , buildStep
          ]
      , jobShell = Some "bash"
      , jobWD = Some "/somewhere"
      , jobParallelism = Some 4
      , jobEnv = [] : List types.EnvVar
      , jobResourceClass = Some types.ResourceClass.FourGPU
      }

let buildMacJob =
      { jobName = "macos-build"
      , jobExec = types.JobExecConfig.NamedExec "someMacOSExecutor"
      , jobSteps = [ types.Step.Checkout, buildStep ]
      , jobShell = Some "tcsh"
      , jobWD = None Text
      , jobParallelism = None Natural
      , jobEnv = [ { envVarName = "ON_MAC", envVarVal = "TRUE" } ]
      , jobResourceClass = None types.ResourceClass
      }

let buildNixJob =
      { jobName = "nix-build"
      , jobExec = types.JobExecConfig.ExecConfig plainNixDocker
      , jobSteps = [ types.Step.Checkout, buildStep ]
      , jobShell = None Text
      , jobWD = None Text
      , jobParallelism = None Natural
      , jobEnv = [] : List types.EnvVar
      , jobResourceClass = None types.ResourceClass
      }

let deployJob =
      { jobName = "deploy"
      , jobExec = types.JobExecConfig.NamedExec "someMachineExecutor"
      , jobSteps =
          [ types.Step.Run
              { stepName = "deploy"
              , stepCommand = "./deploy.sh --production --yolo"
              }
          ]
      , jobShell = None Text
      , jobWD = None Text
      , jobParallelism = None Natural
      , jobEnv = [] : List types.EnvVar
      , jobResourceClass = None types.ResourceClass
      }

let jobs = [ buildLinuxJob, buildMacJob, buildNixJob, deployJob ]

let workflows =
      { workflowsVersion = 2
      , workflows =
          [ { workflowName = "build-and-deploy"
            , workflowNodes =
                [ { workflowNodeJob = "linux-build"
                  , workflowNodeRequires = [] : List Text
                  }
                , { workflowNodeJob = "macos-build"
                  , workflowNodeRequires = [] : List Text
                  }
                , { workflowNodeJob = "nix-build"
                  , workflowNodeRequires = [] : List Text
                  }
                , { workflowNodeJob = "deploy"
                  , workflowNodeRequires =
                      [ "linux-build", "macos-build", "nix-build" ]
                  }
                ]
            }
          ]
      }

let cfg =
        { version = types.Version.Version21
        , executors = execs
        , jobs = jobs
        , workflows = workflows
        }
      : types.Config

in  cfg
