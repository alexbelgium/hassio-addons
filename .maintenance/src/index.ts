import * as fs from "fs-extra-promise";
import * as path from "path";
import * as request from "request-promise";
import chalk from "chalk";
import * as semver from "semver";

async function run()
{
    const root = "..";

    let dirs = await fs.readdirAsync(root);
    dirs = dirs.filter((source) => !source.startsWith(".") && (fs.lstatSync(path.join(root, source))).isDirectory());

    let first = true;
    let updated = false;
    for (const addon of dirs)
    {
        if (!first)
        {
            console.log(chalk.gray("============================================================="));
        }
        else
        {
            first = false;
        }

        const configPath = path.join(root, addon, "config.json");
        const config = await fs.readJSONAsync(configPath);
        let version = semver.valid(config.version);
        if (!version)
        {
            console.log(chalk.redBright(`version format for addon ${chalk.blue(addon)} not supported: ${config.version}`));
            continue;
        }

        console.log(`loaded ${chalk.blue(addon)} ${chalk.cyanBright(version)}`);

        if (!config.maintenance || !config.maintenance.github_release)
        {
            console.log(chalk.yellow("no valid maintenace section found, skipping"));
            continue;
        }

        const dockerFilePath = path.join(root, addon, "Dockerfile");
        const dockerFile = (await fs.readFileAsync(dockerFilePath)).toString();
        const dockerBaseImageLine = dockerFile.split("\n")[0];
        const parts = dockerBaseImageLine.split(":");
        const image = parts[0].replace("FROM ", "");
        const tag = parts[1];

        const releaseInfo = await request({
            uri: `${config.maintenance.github_release}/releases/latest`,
            json: true
        });

        if (tag == releaseInfo.tag_name)
        {
            console.log(chalk.greenBright(`base image ${image}:${chalk.magenta(tag)} is up-to-date`))
        }
        else
        {
            console.log(chalk.yellowBright(`updating base image from ${image}:${chalk.magenta(tag)} to ${image}:${chalk.magenta(releaseInfo.tag_name)}`));
            await fs.writeFileAsync(dockerFilePath, dockerFile.replace(`${image}:${tag}`, `${image}:${releaseInfo.tag_name}`));
            const newVersion = semver.inc(version, "patch");
            console.log(chalk.yellow(`bumping version from ${chalk.cyanBright(version)} to ${chalk.cyanBright(newVersion)}`));
            config.version = newVersion;
            await fs.writeJSONAsync(configPath, config);
            updated = true;
        }
    }
};

run();