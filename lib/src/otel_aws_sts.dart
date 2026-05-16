// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_aws_sts_suppression.dart';

const _tracerName = 'dartastic_otel_libs_aws_sts';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an AWS STS call (AssumeRole, AssumeRoleWithWebIdentity,
/// GetCallerIdentity, GetSessionToken) in a CLIENT span. Never
/// records the access key id or session token.
Future<T> tracedAwsSts<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? roleArn,
  String? roleSessionName,
  int? durationSeconds,
  String? region,
}) async {
  if (awsStsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'rpc.system': 'aws-api',
    'rpc.service': 'STS',
    'rpc.method': operation,
  };
  if (roleArn != null) m['aws.sts.role.arn'] = roleArn;
  if (roleSessionName != null) {
    m['aws.sts.role_session.name'] = roleSessionName;
  }
  if (durationSeconds != null) {
    m['aws.sts.duration_seconds'] = durationSeconds;
  }
  if (region != null) m['cloud.region'] = region;

  final span = _tracer().startSpan(
    'sts $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
