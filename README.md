# dhall-circleci

Use Dhall to Generate CircleCI YAML

To run the (very small) exmaple:

```
$ dhall-to-yaml <<< './Example.dhall'
```

There are some missing fields in the schema, but CircleCI 2 job and workflow
specifications are supported. The key advantage of using Dhall to generate this
YAML is the ability to roll your own build matrix definition (a feature sorely
missing from CircleCI), which you can then map to this simple schema however you
see fit.
