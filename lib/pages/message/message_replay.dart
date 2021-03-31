import 'package:cry/cry_buttons.dart';
import 'package:cry/form/cry_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin/api/message_api.dart';
import 'package:flutter_admin/models/message.dart';
import 'package:flutter_admin/models/message_replay_model.dart';
import 'package:get/get.dart';

class MessageReplay extends StatefulWidget {
  final Message message;

  const MessageReplay({Key key, this.message}) : super(key: key);

  @override
  _MessageReplayState createState() => _MessageReplayState();
}

class _MessageReplayState extends State<MessageReplay> {
  GlobalKey<FormState> formKey = GlobalKey();
  MessageReplayModel messageReplayModel = MessageReplayModel();

  @override
  void initState() {
    messageReplayModel.messageId = widget.message.id;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var form = Form(
      key: formKey,
      child: Column(
        children: [
          CryInput(
            maxLines: 5,
            required: true,
            onSaved: (v) {
              messageReplayModel.content = v;
            },
          ),
        ],
      ),
    );
    var buttonBar = ButtonBar(
      alignment: MainAxisAlignment.center,
      children: [
        CryButtons.commit(context, commit),
        CryButtons.cancel(context, () => Get.back()),
      ],
    );
    var result = Scaffold(
      appBar: AppBar(title: Text('回复-' + widget.message.title)),
      body: Column(
        children: [
          form,
          buttonBar,
        ],
      ),
    );
    return result;
  }

  commit() async {
    if (!formKey.currentState.validate()) {
      return;
    }
    formKey.currentState.save();
    var result = await MessageApi.replayCommit(messageReplayModel.toMap());
    if (result.success) {
      Get.back();
    }
  }
}
