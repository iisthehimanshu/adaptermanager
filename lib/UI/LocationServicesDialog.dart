import 'package:flutter/material.dart';

class LocationServicesDialog extends StatelessWidget {
  const LocationServicesDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and Title Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  const Text(
                    'Turn on Location Services for your iPhone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),

            // Instructions Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildStep('assets/settings.png','1', 'Open the Settings app'),
                  const SizedBox(height: 10),
                  _buildStep('assets/privacy.png','2', 'Tap Privacy & Security'),
                  const SizedBox(height: 10),
                  _buildStep('assets/location.png','3', 'Tap Location Services'),
                  const SizedBox(height: 10),
                  _buildStep('assets/toggle.png','4', 'Toggle Location Services ON'),
                ],
              ),
            ),

            // Buttons Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        backgroundColor: Colors.lightBlueAccent.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String asset, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 46,
            width: 46,
            child: Image.asset(asset, package: "adapter_manager")),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              "$number. $text",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}