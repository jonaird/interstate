library;
import 'dart:async';

import 'package:json/json.dart';
import 'package:macros/macros.dart';
import 'package:uuid/uuid.dart';


Future<bool> runProgram(
  Set<ProgramNode> nodes, {
  mockNetwork = false,
  String? mockedId
,}) async {
  // if (mockNetwork)
  //   for (final node in nodes) node.main();
  // else {
  //   final programNode = nodes.singleWhere((node) => node.id == mockedId);
  //   programNode.main();
  // }
  // return true;
  throw UnimplementedError();
}

class MessageChannel {
  final bool _mocked;
  final ProgramNodeId parentNodeId;
  final _openInvocations = <Uuid, OpenMethodInvocation>{};

  MessageChannel({bool mocked = false, required this.parentNodeId,}) : _mocked = mocked;

  void sendMessage(NodeMessage message){
    throw UnimplementedError();
  }

  void onReceiveMessage(NodeMessage message){
    switch(message){
      case MethodReturnMessage():
        final openMethodInvocation = _openInvocations[message.invocationId];
        if(openMethodInvocation==null) throw MethodReturnInvocationNotFoundException();
        assert(message.invocationId==openMethodInvocation.invocation.id);
        openMethodInvocation.methodReturn=message.returnValue;
    }
    // if(message is MethodReturnMessage){
    //   final openMethodInvocation = _openInvocations[message.invocationId];
    //   if(openMethodInvocation==null) throw MethodReturnInvocationNotFoundException();
    //   assert(message.invocationId==openMethodInvocation.invocation.id);
    //   openMethodInvocation.methodReturn=message.returnValue;
    // }
    throw UnimplementedError();
  }
  
  Future<MethodReturn> callMethodOnProgramNode(ProgramNodeId node, MethodInvocation invocation) async {
    final openMethodInvocation = OpenMethodInvocation(invocation: invocation);
    _openInvocations[invocation.id]=openMethodInvocation;
    sendMessage(MethodCallMessage(target: node, source: parentNodeId, invocation: invocation));
    await openMethodInvocation.waitForMethodReturn();
    return openMethodInvocation.methodReturn!;
  }



}

class _ReturnCompleter {
  final MethodInvocation invocation;
  MethodReturn? methodReturn;
  _ReturnCompleter(this.invocation);
}

enum MethodCallStatus{
  registered,
  sent,
  returned,
  error
}

macro class ProgramNode implements ClassDeclarationsMacro{
  const ProgramNode();

   @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration targetClass, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromParts([

    ]));

    final classMethods = await builder.methodsOf(targetClass);
    builder.declareInType(DeclarationCode.fromParts([
      'Map<String, dynamic>? applyMethodCall(String methodName, Object? argument) async {',
        for(final method in classMethods)
          '''if(methodName == ${method.identifier.name}) {
            final value = ${method.identifier.name}(argument as ${method.returnType});
            if(value is Future) value = await value;
            return value.toMessageJson();
          }''',
          'throw(NoSuchMethodError());'
    ]));
    throw UnimplementedError();
  }
}


class NodeMessage {
  final Uuid id;
  final ProgramNodeId target;
  final ProgramNodeId source;
  final DateTime timestamp;
  NodeMessage({required this.target, required this.source, DateTime? timestamp,}):timestamp=timestamp??DateTime.now(), id=Uuid();
}

abstract class MethodInvocationMessage extends NodeMessage{
  MethodInvocationMessage({required super.target, required super.source, super.timestamp,});
  Uuid get invocationId;
}

class MethodCallMessage extends MethodInvocationMessage {
  final MethodInvocation invocation;
  MethodCallMessage({required super.target, required super.source, required this.invocation, super.timestamp ,});

  @override
  Uuid get invocationId => invocation.id;
}

class MethodReturnMessage extends MethodInvocationMessage {
  final MethodReturn returnValue;
  @override
  final Uuid invocationId;
  MethodReturnMessage({required super.target, required super.source, super.timestamp, required this.invocationId, required this.returnValue,});
}

class MethodInvocation {
  final Uuid id;
  final String objectInstancePath;
  final String methodName;
  final JsonCodable argument;
  final DateTime timestamp;
  MethodInvocation({required this.objectInstancePath, required this.methodName, required this.argument, required this.timestamp,}):id=Uuid();
}

class MethodReturn {
  final String id;
  final DateTime timestamp;
  final JsonCodable value;
  MethodReturn({required this.id, required this.timestamp, required this.value,});
}


// abstract class ProgramNode {
//   final String id;
//   ProgramNode({required this.id,});

//   void main();
// }

// abstract class AddressableNode extends ProgramNode {
//   AddressableNode({required String address,}) : super(id: address);
// }

// abstract class NonddressableNode extends ProgramNode {
//   NonddressableNode({required super.id,});
// }

class ProgramNodeId {
  final String id;
  ProgramNodeId(this.id);
}

class OpenMethodInvocation{
  final MethodInvocation invocation;
  MethodReturn? _methodReturn;
  final _completer = Completer<MethodReturn>();
  OpenMethodInvocation({required this.invocation});
  
  MethodReturn? get methodReturn => _methodReturn;

  set methodReturn(MethodReturn? methodReturn){
    assert(methodReturn==null);
    _methodReturn = methodReturn;
    _completer.complete(methodReturn);
  }

  
  Future<void> waitForMethodReturn() async {
    await _completer.future;
    return;
  }
}

class MethodReturnInvocationNotFoundException implements Exception{
  
}