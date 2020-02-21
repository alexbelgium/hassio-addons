import * as fs from "fs-extra-promise";
import * as path from "path";
import { Manager } from "../manager";
import { build } from "./build";
import * as spawn from "cross-spawn";
import { ChildProcess } from "child_process";

export async function run(manager: Manager, opts: any)
{
    const addon = opts.addon;

    const addonPath = manager.getAddonPath(addon);
    const addonTmpPath = manager.getAddonTmpPath(addon);

    if (!await fs.existsAsync(addonPath))
    {
        console.error(`addon ${addon} not found`);
        process.exit(1);
    }

    const config = await manager.getAddonConfig(addon);

    const shareTmpPath = path.join(addonTmpPath, "share");
    const configTmpPath = path.join(addonTmpPath, "config");
    const dataTmpPath = path.join(addonTmpPath, "data");
    const optionsFilePath = path.join(dataTmpPath, "options.json");

    if (opts.clean)
    {
        await fs.removeAsync(addonTmpPath);
    }

    await fs.ensureDirAsync(shareTmpPath);
    await fs.ensureDirAsync(configTmpPath);
    await fs.ensureDirAsync(dataTmpPath);

    if (!await fs.existsAsync(optionsFilePath))
    {
        await fs.writeJSONAsync(optionsFilePath, config.options);
    }

    if (!opts.nobuild)
    {
        console.log("building image(s)");
        await build(manager, { addon, nocheck: true, arch: "--amd64" });
    }

    let args =
        [
            "run",
            "--rm",
            "-v",
            `${path.resolve(shareTmpPath)}:/share`,
            "-v",
            `${path.resolve(configTmpPath)}:/config`,
            "-v",
            `${path.resolve(dataTmpPath)}:/data`,
            ...[].concat(...Object.keys(config.ports).map(x => ["-p", `${config.ports[x]}:${config.ports[x]}`])),
            ...[].concat(...(config.privileged || []).map(x => ["--cap-add", `${x}`])),
            ...[].concat(...Object.keys(config.environment || {}).map(x => ["-e", `${x}=${config.environment[x]}`])),
            "--name",
            addon,
            `petersendev/hassio-${addon}-amd64:latest`
        ];

    let child: ChildProcess;

    function exit(signal: string)
    {
        if (child)
        {
            console.log(`killing process (${signal})`);
            child.kill(signal);
        }

        console.log("stopping container for reuse");
        spawn.sync("docker", ["stop", addon], { stdio: 'inherit' });
        console.log("exiting");
        process.exit(0);
    }

    process.on('SIGINT', exit);
    child = spawn("docker", args, { stdio: 'inherit' });
}