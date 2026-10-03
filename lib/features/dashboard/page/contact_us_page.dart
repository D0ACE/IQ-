import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/common_gradient_button.dart';
import 'package:iq_plus/common/routes/go_route.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/components/background.dart';
import 'package:iq_plus/common/utility/app_validation.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.blackColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
        title: const Text(
          "Contact Us",
          style: TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Background(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 1.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Get in Touch",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                      "We’d love to hear from you! Whether you have a question or feedback, reach out to us."),
                  const SizedBox(height: 20),

                  // Address
                  _infoTile(
                      Icons.location_on,
                      "Address",
                      "Hindustan Standards Bureau (HSB) \nNo 85, 3rd Floor, Near Dairy Circle Bus stop, \nHegganahalli Main Road, Peenya 2nd Stage, \nBangalore- 560058"),
                  const SizedBox(height: 10),

                  // Phone
                  _infoTile(Icons.phone, "Phone", "080-23282163, +91 7892355589"),
                  const SizedBox(height: 10),

                  // Email
                  _infoTile(Icons.email, "Email", "info@hsagroups.com \nsales@hsagroups.com"),
                  const SizedBox(height: 20),

                  const Text("Send a Message",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: "Your Name", border: OutlineInputBorder()),
                          validator: AppValidation.nameValidator,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: "Your Email", border: OutlineInputBorder()),
                          validator: AppValidation.checkEmailValidation,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: "Message", border: OutlineInputBorder()),
                          validator: AppValidation.messageValidator,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GradientButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Message sent successfully!")),
                        );
                      }
                    },
                    text: "Submit",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String detail) {
    return Row(
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(detail),
          ],
        ),
      ],
    );
  }
}
