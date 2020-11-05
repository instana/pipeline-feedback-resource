# Instana Pipeline Feedback Concourse Resource

Instana [Pipeline Feedback](https://www.instana.com/docs/pipeline_feedback/) is an automatic analysis of application development and deployment pipeline events, correlated directly with application, infrastructure, and service performance data.

This [Concourse](https://concourse-ci.org/) resource allows you to easily create new releases in Instana from the comfort and general awesomeness of your Concourse pipelines.

## Source Configuration

* `endpoint`: *Required.* The URL of your Instana backend, including the protocol (`https`) and, with self-managed (a.k.a. on-prem) units, the port; do not include the path. So, `https://my-unit.instana.io` or `https://my-unit.my-domain:1444` are good, `https://my-unit.instana.io/api` is not.

* `api_token`: A valid [API token](https://www.instana.com/docs/api/web/#tokens) with the `Configuration of releases` permissions.

### Example

``` yaml
resource_types:

  - name: instana-pipeline-feedback
    type: docker-image
    source:
      repository: instana/pipeline-feedback-resource
      tag: latest

resources:

  - name: my-release
    type: instana-pipeline-feedback
    source:
      endpoint: https://awesome-tenant.instana.io
      api_token: ((instana_api_token)) # Use secrets if you can!
```

Retrieving the latest release:

``` yaml
- get: my-release
```

Creating a new release with, as name, then content of the `my/release/name` file and the time of execution of the `put` step as timestamp:

```yaml
- put: my-release
  params:
    release_name_file: my/release/name
```

Creating a new release with default name, built as `${BUILD_PIPELINE_NAME}/${BUILD_NAME} #${BUILD_ID}` using [Concourse's resource metadata](https://concourse-ci.org/implementing-resource-types.html#resource-metadata):

```yaml
- put: my-release
```

Creating a new release with, as name, then content of the `my/release/name` file and, as timestamp, the content of the `my/release/timestamp` file:

```yaml
- put: my-release
  params:
    release_name_file: my/release/name
    start_file: my/release/timestamp
```

## Timestamps in Instana

Notice that _timestamps are in milliseconds since the Epoch_. Time for all Instana is in milliseconds, and the APIs reflect it, which means that the timestamps have three digits more than the usual values you get with, say, a `date +%s`.

When in doubt, add three `0`s :-)

## Behavior

### Check: Find newer releases

Check for new releases.
If no releases are found in the Instana backend, the `get` will fail.

While you may find the failure upon no releases found to be surprising the first time around, it will give you much better control of the flow using the [`on_error` handlers](https://concourse-ci.org/jobs.html#schema.job.on_error) of Concourse.

### In: Retrieve the lastest release

Retrieve metadata of the latest releases.
The following additional files are populated:

* `name`: the name of the release
* `id`: the id of the release
* `start`: timestamp associated with the release, in milliseconds since the Epoch (see [Timestamps in Instana](#timestamps-in-instana) for the rationale).
* `last_updated`: the timestamp of the last time the release has been updated, in milliseconds since the Epoch (see [Timestamps in Instana](#timestamps-in-instana) for the rationale).

### Out: Create a new release

Create a new release in Instana.

#### Parameters

* `release_name_file`: *Optional.* Path to the file containing the name to be given to the release.
  If not set, the release name will be set to `${BUILD_PIPELINE_NAME}/${BUILD_NAME} #${BUILD_ID}`, relying on Concourse's [resource metadata](https://concourse-ci.org/implementing-resource-types.html#resource-metadata).

* `start_file`: *Optional.* Path to the file containing the timestamp to set as start time of the release.
  If not set, the current time will be used.
  The value in the `start_file` will be interpreted as in milliseconds since the Epoch (see [Timestamps in Instana](#timestamps-in-instana) for the rationale), so beware that, if you forget to add the milliseconds, you will likely create releases starting somewhen in Jan 1970.
  (Make that Flux capacitor purr!)

* `scope_file`: *Otional.* Path to the file containing the scoping information for the release in terms of Application Perspectives and Services.
  The file should contain valid JSON object that satisfies `jq type == 'object'`, and it can have as top-level fields `applications` and `services`, which respectively have the same structure as in the [API documentation for creating releases](https://instana.github.io/openapi/#operation/postRelease), e.g.:

  ```json
  {
    "applications": [
      { "name": "My Awesome App" },
      { "name": "My Even More Awesome App" },
    ],
    "services": [
      { "name": "Cool service #1" },
      {
        "name": "Cool service #2",
        "scopedTo": {
          "applications": [
            { "name": "My Cool App" }
          ]
        }
      }
    ]
  }
  ```

  The JSON snippet above will scope the new release to apply to the entirety of the Application Perspectives `My Awesome App` and `My Even More Awesome App`, to the entirely of the `Cool service #1` service, and to the `Cool service #2` service, but only to what part of `Cool service #2` is included in the `My Cool App` Application Perspective.
  For moe information on Application Perspectives, Services and the scoping, refer to the [Application Monitoring](https://www.instana.com/docs/application_monitoring) documentation.

## Support

To ensure we do not miss your requests, we disabled the Issues functionality for this repository.
If you have questions about how to use Concourse resource, please open a [support request](https://support.instana.com/hc/en-us/requests/new).

## Development

The actions of the resource are written in `bash`, `curl` and `jq`, with the goal of being easy to debug in local even from inside a Docker image (hello, [`fly intercept`](https://concourse-ci.org/builds.html#fly-intercept)!).
The test scripts assumes a local Docker daemon.

## Contributing

Ah, our kind of person!
Go ahead, open a PR.

Please be aware that we will be able to accept only code contributed under the Apache 2.0 license.
