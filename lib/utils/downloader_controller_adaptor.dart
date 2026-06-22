import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/controller/transmission/transmission_controller.dart';

class DownloaderControllerAdaptor {
  static DownloaderControllerProtocol getController(DownloaderConfig config) {
    switch (config.type) {
      case DownloaderType.qbittorrent:
        return QBController(config: config);
      case DownloaderType.transmission:
        return TransmissionController(config: config);
    }
  }
}
