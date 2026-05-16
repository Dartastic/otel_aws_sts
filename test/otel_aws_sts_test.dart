// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_aws_sts/otel_aws_sts.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_aws_sts-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('AssumeRole records CLIENT span', () async {
    await tracedAwsSts<String>(
      operation: 'AssumeRole',
      roleArn: 'arn:aws:iam::123:role/Deploy',
      roleSessionName: 'session-1',
      durationSeconds: 3600,
      region: 'us-east-1',
      invoke: () async => 'creds-redacted',
    );
    final a = attrsOf(spans.findSpanByName('sts AssumeRole')!);
    expect(a['rpc.service'], 'STS');
    expect(a['aws.sts.role.arn'], 'arn:aws:iam::123:role/Deploy');
    expect(a['aws.sts.role_session.name'], 'session-1');
    expect(a['aws.sts.duration_seconds'], 3600);
  });

  test('suppression skips spans', () async {
    await runWithoutAwsStsInstrumentationAsync(() async {
      await tracedAwsSts<String>(
        operation: 'GetCallerIdentity',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('sts '), isEmpty);
  });
}
