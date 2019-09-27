let types = ./Schema.dhall

let render = ./Render.dhall

let rdfDocker = { dockerImageName = "nixos/nix:2.2.1" }

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
      , jobDocker =
          rdfDocker
      , jobSteps =
          [ updateStep
          , freedomStep
          , installStep
          , types.Step.Checkout
          , configStep
          , cachixStep
          , buildStep
          ]
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

let rdfConfig = { version = 2, jobs = [ buildJob ], workflows = rdfWorkflows }

in  render rdfConfig
