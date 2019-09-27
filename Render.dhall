let types = ./Schema.dhall

let prelude = ./Prelude.dhall

let RenderDocker = { image : Text }

let renderDocker = λ(d : types.Docker) → { image = d.dockerImageName }

let RenderRun = { name : Text, command : Text }

let RenderStep = < run : { run : RenderRun } | checkout >

let renderStep =
      let fs =
            { Run =
                  λ(r : { stepName : Text, stepCommand : Text })
                → RenderStep.run
                  { run = { name = r.stepName, command = r.stepCommand } }
            , Checkout =
                RenderStep.checkout
            }
      
      in  λ(s : types.Step) → merge fs s

let RenderJobValue = { docker : RenderDocker, steps : List RenderStep }

let RenderJob = { mapKey : Text, mapValue : RenderJobValue }

let renderJob =
        λ(j : types.Job)
      → { mapKey =
            j.jobName
        , mapValue =
            { docker =
                renderDocker j.jobDocker
            , steps =
                prelude.map types.Step RenderStep renderStep j.jobSteps
            }
        }

let RenderWorkflowNode =
      < NoRequirements :
          Text
      | WithRequirements :
          List { mapKey : Text, mapValue : { requires : List Text } }
      >

let renderWorkflowNode =
        λ(n : types.WorkflowNode)
      →       if Natural/isZero (List/length Text n.workflowNodeRequires)
        
        then  RenderWorkflowNode.NoRequirements n.workflowNodeJob
        
        else  RenderWorkflowNode.WithRequirements
              [ { mapKey =
                    n.workflowNodeJob
                , mapValue =
                    { requires = n.workflowNodeRequires }
                }
              ]

let RenderWorkflow = { jobs : List RenderWorkflowNode }

let RenderWorkflowVal = < Version : Natural | Workflow : RenderWorkflow >

let renderWorkflow =
        λ(w : types.Workflow)
      → { mapKey =
            w.workflowName
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
      →   [ { mapKey =
                "version"
            , mapValue =
                RenderWorkflowVal.Version w.workflowsVersion
            }
          ]
        # prelude.map types.Workflow RenderWorkflows renderWorkflow w.workflows

let Renderable =
      { version :
          Natural
      , jobs :
          List RenderJob
      , workflow :
          List RenderWorkflows
      }

let render =
        λ(c : types.Config)
      →   { version =
              c.version
          , jobs =
              prelude.map types.Job RenderJob renderJob c.jobs
          , workflow =
              renderWorkflows c.workflows
          }
        : Renderable

in  render
