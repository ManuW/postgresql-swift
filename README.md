[API Documentation: Click here](https://manuw.github.io/postgresql-swift/docs/)

# postgresql-swift

PostgreSQL swift adapter

More or less comments are take from [PostgreSQL documentation](https://www.postgresql.org/docs/10/static/libpq.html)

## State of the API

Work in progress.

The adapter is not complete and not fully tested.

## Documentation and Examples

The api documentation can be found at: [https://manuw.github.io/postgresql-swift/docs/](https://manuw.github.io/postgresql-swift/docs/)

Under _sources_ are some example folders. The examples have comments.

The examples can be started with the _swift_ command:

```shell
swift run example-1
```

## Generate Documentation

Use [jazzy](https://github.com/realm/jazzy) with following instruction to generate the documentation. After generating the documentation is located at the _doc_ folder.

```shell
jazzy --clean --xcodebuild-arguments -scheme,postgresql-swift-Package -x -target,postgresql-swift --module postgresql_swift --min-acl private
```

## Generate Xcode Project

Use following command to generate an Xcode project.

```shell
swift package generate-xcodeproj
```
