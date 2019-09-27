let Docker = { dockerImageName : Text }

let Step = < Run : { stepName : Text, stepCommand : Text } | Checkout >

let Job = { jobName : Text, jobDocker : Docker, jobSteps : List Step }

let WorkflowNode = { workflowNodeJob : Text, workflowNodeRequires : List Text }

let Workflow = { workflowName : Text, workflowNodes : List WorkflowNode }

let Workflows = { workflowsVersion : Natural, workflows : List Workflow }

let Config = { version : Natural, jobs : List Job, workflows : Workflows }

in  { Docker =
        Docker
    , Step =
        Step
    , Job =
        Job
    , WorkflowNode =
        WorkflowNode
    , Workflow =
        Workflow
    , Workflows =
        Workflows
    , Config =
        Config
    }
