import { injectNativeModules, getFlutterProjectPath } from './include_flutter';

injectNativeModules(__dirname, getFlutterProjectPath(), 1)