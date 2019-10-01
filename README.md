# dhall-circleci

Use Dhall to Generate CircleCI YAML

To run the (very small) exmaple:

```
$ dhall-to-yaml --omitEmpty <<< './Render.dhall ./rdf-example.dhall'
```

If you find any mistakes (which you're more likely to find with features that
aren't used as often), please open an issue.

There are some missing fields in the schema, but CircleCI 2 job and workflow
specifications are supported. The key advantage of using Dhall to generate this
YAML is the ability to roll your own build matrix definition (a feature sorely
missing from CircleCI), which you can then map to this simple schema however you
see fit.

Currently missing major CircleCI features:
- Orbs (CircleCI 2.1)
- Commands (CircleCI 2.1)
- Windows executors
- Job-level branch filters (deprecated, use workflow branch filters)

Assertions that would be nice to have:
- Workflow nodes only mention defined jobs.
- Jobs only mention defined executors.
