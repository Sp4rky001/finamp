import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import '../../models/finamp_models.dart';
import '../../services/finamp_settings_helper.dart';
import '../../services/finamp_user_helper.dart';
import '../../services/isar_downloads.dart';
import '../global_snackbar.dart';

class DownloadDialog extends StatefulWidget {
  const DownloadDialog._build({
    super.key,
    required this.item,
    required this.viewId,
  });

  final DownloadStub item;
  final String viewId;

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();

  static Future<void> show(
      BuildContext context, DownloadStub item, String? viewId) async {
    if (viewId == null) {
      final finampUserHelper = GetIt.instance<FinampUserHelper>();
      viewId = finampUserHelper.currentUser!.currentViewId;
    }
    if (FinampSettingsHelper.finampSettings.downloadLocationsMap.values
            .where((element) =>
                element.baseDirectory != DownloadLocationType.internalDocuments)
            .length ==
        1) {
      final isarDownloads = GetIt.instance<IsarDownloads>();
      unawaited(isarDownloads
          .addDownload(
              stub: item,
              viewId: viewId!,
              downloadLocation:
                  FinampSettingsHelper.finampSettings.internalSongDir)
          .then((value) => GlobalSnackbar.message(
              (scaffold) => AppLocalizations.of(scaffold)!.downloadsAdded)));
    } else {
      await showDialog(
        context: context,
        builder: (context) => DownloadDialog._build(
          item: item,
          viewId: viewId!,
        ),
      );
    }
  }
}

class _DownloadDialogState extends State<DownloadDialog> {
  DownloadLocation? selectedDownloadLocation;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addDownloads),
      content: DropdownButton<DownloadLocation>(
          hint: Text(AppLocalizations.of(context)!.location),
          isExpanded: true,
          onChanged: (value) => setState(() {
                selectedDownloadLocation = value;
              }),
          value: selectedDownloadLocation,
          items: FinampSettingsHelper.finampSettings.downloadLocationsMap.values
              .where((element) =>
                  element.baseDirectory !=
                  DownloadLocationType.internalDocuments)
              .map((e) => DropdownMenuItem<DownloadLocation>(
                    value: e,
                    child: Text(e.name),
                  ))
              .toList()),
      actions: [
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: selectedDownloadLocation == null
              ? null
              : () async {
                  Navigator.of(context).pop();
                  final isarDownloads = GetIt.instance<IsarDownloads>();
                  await isarDownloads
                      .addDownload(
                          stub: widget.item,
                          viewId: widget.viewId,
                          downloadLocation: selectedDownloadLocation!)
                      .onError(
                          (error, stackTrace) => GlobalSnackbar.error(error));

                  GlobalSnackbar.message((scaffold) =>
                      AppLocalizations.of(scaffold)!.downloadsAdded);
                },
          child: Text(AppLocalizations.of(context)!.addButtonLabel),
        )
      ],
    );
  }
}
