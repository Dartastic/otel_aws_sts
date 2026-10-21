// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_aws_sts/otel_aws_sts.dart';

/// Traces AWS STS calls with OpenTelemetry.
///
/// `otel_aws_sts` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each AWS STS call in
/// [tracedAwsSts]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'aws-sts-example');

  // Wraps an AWS STS call (AssumeRole, AssumeRoleWithWebIdentity, GetCallerIdentity, GetSessionToken) in a CLIENT span.
  final awsStsId = await tracedAwsSts<String>(
    operation: 'create',
    roleArn: 'example',
    roleSessionName: 'example',
    durationSeconds: 120,
    region: 'us-east-1',
    invoke: () async {
      // Make the AWS STS call here, then report what it returned.
      return 'aws_sts_8f3a2c';
    },
  );
  OTelLog.info('tracedAwsSts create returned $awsStsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAwsStsInstrumentationAsync.
  await runWithoutAwsStsInstrumentationAsync(
    () => tracedAwsSts<String>(
      operation: 'create',
      roleArn: 'example',
      roleSessionName: 'example',
      durationSeconds: 120,
      region: 'us-east-1',
      invoke: () async {
        return 'aws_sts_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
