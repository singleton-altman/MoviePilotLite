import path from 'path'

export { flutterHvigorPlugin, injectNativeModules } from 'flutter-hvigor-plugin'

export function getFlutterProjectPath(): string {
  return path.dirname(__dirname)
}