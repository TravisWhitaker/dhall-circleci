let types = ./Schema.dhall

let plainImage =
        λ(i : Text)
      → [ { dockerImage =
              i
          , dockerReachableName =
              None Text
          , dockerEntryPoint =
              [] : List Text
          , dockerCommand =
              [] : List Text
          , dockerUser =
              None Text
          , dockerEnv =
              [] : List types.EnvVar
          , dockerLoginAuth =
              None types.DockerLoginAuth
          , dockerAWSAuth =
              None types.DockerAWSAuth
          }
        ]

let rdfDocker = types.ExecConfig.Docker (plainImage "nixos/nix:2.2.1")

let updateStep =
      types.Step.Run
      { stepName =
          "Update nixos-19.03"
      , stepCommand =
          ''
          nix-channel --add https://nixos.org/channels/nixos-19.03 nixpkgs
          nix-channel --update
          ''
      }

let freedomStep =
      types.Step.Run
      { stepName =
          "Forfeit freedom"
      , stepCommand =
          ''
          mkdir -p ~/.config/nixpkgs
          echo "{allowUnfree = true;}" >> ~/.config/nixpkgs/config.nix
          ''
      }

let installStep =
      types.Step.Run
      { stepName =
          "Install Utils"
      , stepCommand =
          ''
          nix-env -u
          nix-env -i coreutils openssh git bash cachix
          ''
      }

let configStep =
      types.Step.Run
      { stepName =
          "Configure Nix"
      , stepCommand =
          ''
          mkdir -p /etc/nix
          echo "build-cores = 2" >> /etc/nix/nix.conf
          ''
      }

let cachixStep =
      types.Step.Run
      { stepName = "Setup Cachix", stepCommand = "cachix use rdf\n" }

let buildStep =
      types.Step.Run
      { stepName =
          "Build rdf"
      , stepCommand =
          ''
          nix-shell --pure --run "cabal new-update && cabal new-build -j$(nproc)"
          ''
      }

let buildJob =
      { jobName =
          "build"
      , jobExec =
          types.JobExecConfig.ExecConfig rdfDocker
      , jobSteps =
          [ updateStep
          , freedomStep
          , installStep
          , types.Step.Checkout
          , configStep
          , cachixStep
          , buildStep
          ]
      , jobShell =
          None Text
      , jobWD =
          None Text
      , jobParallelism =
          None Natural
      , jobEnv =
          [] : List types.EnvVar
      , jobResourceClass =
          None types.ResourceClass
      }

let rdfWorkflows =
      { workflowsVersion =
          2
      , workflows =
          [ { workflowName =
                "build-and-test"
            , workflowNodes =
                [ { workflowNodeJob =
                      "build"
                  , workflowNodeRequires =
                      [] : List Text
                  }
                ]
            }
          ]
      }

let rdfConfig =
      { version =
          types.Version.Version2
      , executors =
          [] : List types.Executor
      , jobs =
          [ buildJob ]
      , workflows =
          rdfWorkflows
      }

in  rdfConfig
