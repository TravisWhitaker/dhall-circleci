let Step = < Run : { stepName : Text, stepCommand : Text } | Checkout >

let WorkflowNode = { workflowNodeJob : Text, workflowNodeRequires : List Text }

let Workflow = { workflowName : Text, workflowNodes : List WorkflowNode }

let Workflows = { workflowsVersion : Natural, workflows : List Workflow }

let Version = < Version2 | Version21 >

let ResourceClass =
      < Small
      | Medium
      | MediumPlus
      | Large
      | XLarge
      | TwoXL
      | TwoXLPlus
      | OneGPU
      | TwoGPU
      | FourGPU
      >

let EnvVar = { envVarName : Text, envVarVal : Text }

let DockerLoginAuth = { authUsername : Text, authPassword : Text }

let DockerAWSAuth = { awsAccessKey : Text, awsSecretKey : Text }

let DockerConfig =
      { dockerImage : Text
      , dockerReachableName : Optional Text
      , dockerEntryPoint : List Text
      , dockerCommand : List Text
      , dockerUser : Optional Text
      , dockerEnv : List EnvVar
      , dockerLoginAuth : Optional DockerLoginAuth
      , dockerAWSAuth : Optional DockerAWSAuth
      }

let MachineConfig = { machineImage : Text, machineLayerCaching : Bool }

let MacOSConfig = { macOSXCode : Text }

let ExecConfig =
      < Docker : List DockerConfig
      | Machine : MachineConfig
      | MacOS : MacOSConfig
      >

let Executor =
      { execName : Text
      , execResourceClass : Optional ResourceClass
      , execShell : Optional Text
      , execWD : Optional Text
      , execEnv : List EnvVar
      , execConfig : ExecConfig
      }

let JobExecConfig = < ExecConfig : ExecConfig | NamedExec : Text >

let Job =
      { jobName : Text
      , jobExec : JobExecConfig
      , jobSteps : List Step
      , jobShell : Optional Text
      , jobWD : Optional Text
      , jobParallelism : Optional Natural
      , jobEnv : List EnvVar
      , jobResourceClass : Optional ResourceClass
      }

let Config =
      { version : Version
      , executors : List Executor
      , jobs : List Job
      , workflows : Workflows
      }

in  { Step = Step
    , WorkflowNode = WorkflowNode
    , Workflow = Workflow
    , Workflows = Workflows
    , Version = Version
    , ResourceClass = ResourceClass
    , EnvVar = EnvVar
    , DockerLoginAuth = DockerLoginAuth
    , DockerAWSAuth = DockerAWSAuth
    , DockerConfig = DockerConfig
    , MachineConfig = MachineConfig
    , MacOSConfig = MacOSConfig
    , ExecConfig = ExecConfig
    , Executor = Executor
    , JobExecConfig = JobExecConfig
    , Job = Job
    , Config = Config
    }
