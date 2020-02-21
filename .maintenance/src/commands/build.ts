import * as path from "path";
import * as spawn from "cross-spawn";
import { Manager } from "../manager";

export async function build(manager: Manager, opts: any)
{
    const addon = opts.addon;
    const config = await manager.getAddonConfig(addon);

    if (!opts.arch)
    {
        opts.arch = config.arch.map(x => `--${x}`);
    }
    else if(!Array.isArray(opts.arch))
    {
        opts.arch = [opts.arch];
    }

    let args = [
        "run",
        "--rm",
        "--privileged",
        "-v",
        "//var/run/docker.sock:/var/run/docker.sock:rw",
        "-v",
        `${path.resolve(manager.rootDir)}:/data:ro`,
        "--name",
        "ha-builder",
        "homeassistant/amd64-builder:latest",
        "--addon",
        ...opts.arch,
        "--test",
        "-t",
        `/data/${addon}`
    ];

    if (!opts.nocheck)
    {
        args = args.concat([
            "--docker-hub",
            "petersendev",
            "--docker-hub-check"
        ]);
    }
    
    const result = spawn.sync("docker", args, { stdio: 'inherit' });
}