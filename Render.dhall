let types = ./Schema.dhall

let prelude = ./Prelude.dhall

let RenderEnvVar = { mapKey : Text, mapValue : Text }

let renderEnvVar =
      λ(e : types.EnvVar) → { mapKey = e.envVarName, mapValue = e.envVarVal }

let RenderDockerAuth = { username : Text, password : Text }

let renderDockerAuth =
        λ(a : types.DockerLoginAuth)
      → { username = a.authUsername, password = a.authPassword }

let RenderAWSAuth = { aws_access_key_id : Text, aws_secret_access_key : Text }

let renderAWSAuth =
        λ(a : types.DockerAWSAuth)
      → { aws_access_key_id = a.awsAccessKey
        , aws_secret_access_key = a.awsSecretKey
        }

let RenderDockerConfig =
      { image : Text
      , name : Optional Text
      , entrypoint : List Text
      , command : List Text
      , user : Optional Text
      , environment : List RenderEnvVar
      , auth : Optional RenderDockerAuth
      , aws_auth : Optional RenderAWSAuth
      }

let renderDockerConfig =
        λ(d : types.DockerConfig)
      → { image = d.dockerImage
        , name = d.dockerReachableName
        , entrypoint = d.dockerEntryPoint
        , command = d.dockerCommand
        , user = d.dockerUser
        , environment =
            prelude.map types.EnvVar RenderEnvVar renderEnvVar d.dockerEnv
        , auth =
            Optional/fold
              types.DockerLoginAuth
              d.dockerLoginAuth
              (Optional RenderDockerAuth)
              (λ(a : types.DockerLoginAuth) → Some (renderDockerAuth a))
              (None RenderDockerAuth)
        , aws_auth =
            Optional/fold
              types.DockerAWSAuth
              d.dockerAWSAuth
              (Optional RenderAWSAuth)
              (λ(a : types.DockerAWSAuth) → Some (renderAWSAuth a))
              (None RenderAWSAuth)
        }

let RenderMachineConfig = { image : Text, docker_layer_caching : Bool }

let renderMachineConfig =
        λ(m : types.MachineConfig)
      → { image = m.machineImage, docker_layer_caching = m.machineLayerCaching }

let RenderMacOSConfig = { xcode : Text }

let renderMacOSConfig = λ(m : types.MacOSConfig) → { xcode = m.macOSXCode }

let RenderExecConfig =
      < Docker : List RenderDockerConfig
      | Machine : RenderMachineConfig
      | MacOS : RenderMacOSConfig
      >

let renderExecConfig =
        λ(c : types.ExecConfig)
      → let fs =
              { Docker =
                    λ(ld : List types.DockerConfig)
                  → RenderExecConfig.Docker
                      ( prelude.map
                          types.DockerConfig
                          RenderDockerConfig
                          renderDockerConfig
                          ld
                      )
              , Machine =
                    λ(m : types.MachineConfig)
                  → RenderExecConfig.Machine (renderMachineConfig m)
              , MacOS =
                    λ(m : types.MacOSConfig)
                  → RenderExecConfig.MacOS (renderMacOSConfig m)
              }
        
        in  merge fs c

let renderExecMapKey =
        λ(rec : RenderExecConfig)
      → let fs =
              { Docker = λ(_ : List RenderDockerConfig) → "docker"
              , Machine = λ(_ : RenderMachineConfig) → "machine"
              , MacOS = λ(_ : RenderMacOSConfig) → "macos"
              }
        
        in  merge fs rec

let renderResourceClass =
        λ(r : types.ResourceClass)
      → let ns =
              { Small = "small"
              , Medium = "medium"
              , MediumPlus = "medium+"
              , Large = "large"
              , XLarge = "xlarge"
              , TwoXL = "2XL"
              , TwoXLPlus = "2XL+"
              , OneGPU = "1GPU"
              , TwoGPU = "2GPU"
              , FourGPU = "4GPU"
              }
        
        in  merge ns r

let RenderExecutorMapVal =
      < ExecConfig : RenderExecConfig
      | ResClass : Optional Text
      | Shell : Optional Text
      | WorkingDir : Optional Text
      | EnvVars : List RenderEnvVar
      >

let RenderExecutor =
      { mapKey : Text
      , mapValue : List { mapKey : Text, mapValue : RenderExecutorMapVal }
      }

let renderExecutor =
        λ(e : types.Executor)
      → let rec = renderExecConfig e.execConfig
        
        in  let recKey = renderExecMapKey rec
            
            in  { mapKey = e.execName
                , mapValue =
                    [ { mapKey = recKey
                      , mapValue = RenderExecutorMapVal.ExecConfig rec
                      }
                    , { mapKey = "resource_class"
                      , mapValue =
                          RenderExecutorMapVal.ResClass
                            ( Optional/fold
                                types.ResourceClass
                                e.execResourceClass
                                (Optional Text)
                                (   λ(rc : types.ResourceClass)
                                  → Some (renderResourceClass rc)
                                )
                                (None Text)
                            )
                      }
                    , { mapKey = "shell"
                      , mapValue = RenderExecutorMapVal.Shell e.execShell
                      }
                    , { mapKey = "working_directory"
                      , mapValue = RenderExecutorMapVal.WorkingDir e.execWD
                      }
                    , { mapKey = "environment"
                      , mapValue =
                          RenderExecutorMapVal.EnvVars
                            ( prelude.map
                                types.EnvVar
                                RenderEnvVar
                                renderEnvVar
                                e.execEnv
                            )
                      }
                    ]
                }

let RenderRun = { name : Text, command : Text }

let RenderStep = < run : { run : RenderRun } | checkout >

let renderStep =
      let fs =
            { Run =
                  λ(r : { stepName : Text, stepCommand : Text })
                → RenderStep.run
                    { run = { name = r.stepName, command = r.stepCommand } }
            , Checkout = RenderStep.checkout
            }
      
      in  λ(s : types.Step) → merge fs s

let RenderJobExecConfig = < ExecConfig : RenderExecConfig | NamedExec : Text >

let renderJobExecConfig =
        λ(j : types.JobExecConfig)
      → let fs =
              { ExecConfig =
                    λ(c : types.ExecConfig)
                  → RenderJobExecConfig.ExecConfig (renderExecConfig c)
              , NamedExec = λ(n : Text) → RenderJobExecConfig.NamedExec n
              }
        
        in  merge fs j

let renderJobExecMapKey =
        λ(rjc : RenderJobExecConfig)
      → let fs =
              { ExecConfig = λ(c : RenderExecConfig) → renderExecMapKey c
              , NamedExec = λ(_ : Text) → "executor"
              }
        
        in  merge fs rjc

let RenderJobMapVal =
      < ExecConfig : RenderJobExecConfig
      | Shell : Optional Text
      | Steps : List RenderStep
      | WorkingDir : Optional Text
      | Parallel : Optional Natural
      | EnvVars : List RenderEnvVar
      | ResClass : Optional Text
      >

let RenderJob =
      { mapKey : Text
      , mapValue : List { mapKey : Text, mapValue : RenderJobMapVal }
      }

let renderJob =
        λ(j : types.Job)
      → let rjc = renderJobExecConfig j.jobExec
        
        in  let rjcKey = renderJobExecMapKey rjc
            
            in  { mapKey = j.jobName
                , mapValue =
                    [ { mapKey = rjcKey
                      , mapValue = RenderJobMapVal.ExecConfig rjc
                      }
                    , { mapKey = "shell"
                      , mapValue = RenderJobMapVal.Shell j.jobShell
                      }
                    , { mapKey = "steps"
                      , mapValue =
                          RenderJobMapVal.Steps
                            ( prelude.map
                                types.Step
                                RenderStep
                                renderStep
                                j.jobSteps
                            )
                      }
                    , { mapKey = "working_directory"
                      , mapValue = RenderJobMapVal.WorkingDir j.jobWD
                      }
                    , { mapKey = "parallelism"
                      , mapValue = RenderJobMapVal.Parallel j.jobParallelism
                      }
                    , { mapKey = "environment"
                      , mapValue =
                          RenderJobMapVal.EnvVars
                            ( prelude.map
                                types.EnvVar
                                RenderEnvVar
                                renderEnvVar
                                j.jobEnv
                            )
                      }
                    , { mapKey = "resource_class"
                      , mapValue =
                          RenderJobMapVal.ResClass
                            ( Optional/fold
                                types.ResourceClass
                                j.jobResourceClass
                                (Optional Text)
                                (   λ(rc : types.ResourceClass)
                                  → Some (renderResourceClass rc)
                                )
                                (None Text)
                            )
                      }
                    ]
                }

let RenderWorkflowNode =
      < NoRequirements : Text
      | WithRequirements :
          List { mapKey : Text, mapValue : { requires : List Text } }
      >

let renderWorkflowNode =
        λ(n : types.WorkflowNode)
      →       if Natural/isZero (List/length Text n.workflowNodeRequires)
        
        then  RenderWorkflowNode.NoRequirements n.workflowNodeJob
        
        else  RenderWorkflowNode.WithRequirements
                [ { mapKey = n.workflowNodeJob
                  , mapValue = { requires = n.workflowNodeRequires }
                  }
                ]

let RenderWorkflow = { jobs : List RenderWorkflowNode }

let RenderWorkflowVal = < Version : Natural | Workflow : RenderWorkflow >

let renderWorkflow =
        λ(w : types.Workflow)
      → { mapKey = w.workflowName
        , mapValue =
            RenderWorkflowVal.Workflow
              { jobs =
                  prelude.map
                    types.WorkflowNode
                    RenderWorkflowNode
                    renderWorkflowNode
                    w.workflowNodes
              }
        }

let RenderWorkflows = { mapKey : Text, mapValue : RenderWorkflowVal }

let renderWorkflows =
        λ(w : types.Workflows)
      →   [ { mapKey = "version"
            , mapValue = RenderWorkflowVal.Version w.workflowsVersion
            }
          ]
        # prelude.map types.Workflow RenderWorkflows renderWorkflow w.workflows

let renderVersion =
      λ(v : types.Version) → merge { Version2 = 2.0, Version21 = 2.1 } v

let Renderable =
      { version : Double
      , executors : List RenderExecutor
      , jobs : List RenderJob
      , workflow : List RenderWorkflows
      }

let render =
        λ(c : types.Config)
      →   { version = renderVersion c.version
          , executors =
              prelude.map
                types.Executor
                RenderExecutor
                renderExecutor
                c.executors
          , jobs = prelude.map types.Job RenderJob renderJob c.jobs
          , workflow = renderWorkflows c.workflows
          }
        : Renderable

in  render
