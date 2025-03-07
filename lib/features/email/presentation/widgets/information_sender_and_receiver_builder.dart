
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/extensions/presentation_email_extension.dart';
import 'package:tmail_ui_user/features/base/widget/email_avatar_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/controller/single_email_controller.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_receiver_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_sender_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/received_time_builder.dart';

class InformationSenderAndReceiverBuilder extends StatelessWidget {

  final SingleEmailController controller;
  final PresentationEmail emailSelected;
  final ResponsiveUtils responsiveUtils;
  final ImagePaths imagePaths;

  const InformationSenderAndReceiverBuilder({
    Key? key,
    required this.controller,
    required this.emailSelected,
    required this.responsiveUtils,
    required this.imagePaths
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: emailSelected.numberOfAllEmailAddress() > 0
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
        children: [
          EmailAvatarBuilder(emailSelected: emailSelected),
          const SizedBox(width: 16),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            return Transform(
              transform: Matrix4.translationValues(0.0, -5.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emailSelected.from?.isNotEmpty == true)
                    Row(children: [
                      Expanded(child: Transform(
                        transform: Matrix4.translationValues(-5.0, 0.0, 0.0),
                        child: EmailSenderBuilder(
                          emailAddress: emailSelected.from!.first,
                          openEmailAddressDetailAction: controller.openEmailAddressDialog,
                        )
                      )),
                      const SizedBox(width: 12),
                      ReceivedTimeBuilder(emailSelected),
                    ]),
                  if (emailSelected.numberOfAllEmailAddress() > 0)
                    EmailReceiverBuilder(
                      controller: controller,
                      emailSelected: emailSelected,
                      responsiveUtils: responsiveUtils,
                      imagePaths: imagePaths,
                      maxWidth: constraints.maxWidth,
                    )
                ]
              ),
            );
          })),
        ]
      ),
    );
  }
}