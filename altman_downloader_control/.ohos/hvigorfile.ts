import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { flutterHvigorPlugin, getFlutterProjectPath } from './include_flutter';

export default {
    system: appTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins:[flutterHvigorPlugin(getFlutterProjectPath(), 1)]         /* Custom plugin to extend the functionality of Hvigor. */
}