import * as fs from "fs-extra-promise";
import * as path from "path";
import * as request from "request-promise";
import chalk from "chalk";
import * as semver from "semver";
import * as yargs from "yargs";


const argv = yargs
    .option("patch", {
        alias: "p",
        default: false
    })
    .argv;

async function run(opts: { patch: boolean })
{
    const root = "..";

    let dirs = await fs.readdirAsync(root);
    dirs = dirs.filter((source) => !source.startsWith(".") && (fs.lstatSync(path.join(root, source))).isDirectory());

    let first = true;
    let updated = false;
    for (const addon of dirs)
    {
        if (addon === "tmp")
        {
            continue;
        }

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

        const versionRegex = config.maintenance.version_regex ? new RegExp(config.maintenance.version_regex) : null;
        const releaseRegex = config.maintenance.release_regex ? new RegExp(config.maintenance.release_regex) : null;

        const addonPath = path.join(root, addon);
        const changelogPath = path.join(addonPath, "CHANGELOG.md");
        const dockerFilePath = path.join(addonPath, "Dockerfile");
        const dockerFile = (await fs.readFileAsync(dockerFilePath)).toString();
        const dockerBaseImageLine = dockerFile.split("\n")[0];
        const parts = dockerBaseImageLine.split(":");
        const image = parts[0].replace("FROM ", "");
        const tag = parts[1];

        const releaseInfo = await request({
            uri: `${config.maintenance.github_release}/releases/latest`,
            json: true
        });

        let coloredTag = tag;
        let appVersion = "";
        if (versionRegex)
        {
            const r = versionRegex.exec(tag);
            if (r && r.length > 1)
            {
                appVersion = r[1];
                coloredTag = tag.replace(appVersion, chalk.yellowBright(appVersion));
            }
        }

        if (releaseRegex)
        {
            const r = releaseRegex.exec(releaseInfo.tag_name);
            if (r && r.length > 1)
            {
                releaseInfo.tag_name = r[1];
            }
        }

        if (tag == releaseInfo.tag_name)
        {
            console.log(chalk.greenBright(`base image ${image}:${chalk.magenta(coloredTag)} is up-to-date`))
        }
        else
        {
            let newAppVersion = "";
            let newColoredTag = releaseInfo.tag_name;
            if (versionRegex)
            {
                const nr = versionRegex.exec(releaseInfo.tag_name);
                if (nr && nr.length > 1)
                {
                    newAppVersion = nr[1];
                    newColoredTag = newColoredTag.replace(newAppVersion, chalk.yellowBright(newAppVersion));
                }
            }

            let minorUpgrade = appVersion && newAppVersion && appVersion != newAppVersion;

            if (!opts.patch && !minorUpgrade)
            {
                console.log(chalk.gray(`ignoring patch for ${image}:${chalk.magenta(coloredTag)} to ${image}:${chalk.magenta(newColoredTag)}`))
            }
            else
            {
                console.log(chalk.yellowBright(`updating base image from ${image}:${chalk.magenta(coloredTag)} to ${image}:${chalk.magenta(newColoredTag)}`));
                await fs.writeFileAsync(dockerFilePath, dockerFile.replace(`${image}:${tag}`, `${image}:${releaseInfo.tag_name}`));

                const newVersion = semver.inc(version, minorUpgrade ? "minor" : "patch");
                console.log(chalk.yellow(`bumping version from ${chalk.cyanBright(version)} to ${chalk.cyanBright(newVersion)}`));
                config.version = newVersion;
                await fs.writeJSONAsync(configPath, config);

                let oldChangelog = "";
                if (await fs.existsAsync(changelogPath))
                {
                    oldChangelog = (await fs.readFileAsync(changelogPath)).toString();
                }

                let changelog = `## ${newVersion}\n\n - ${minorUpgrade ?
                    `Update ${config.name} to ${newAppVersion} (${image}:${releaseInfo.tag_name})` :
                    `Update base image to ${image}:${releaseInfo.tag_name}`}`;

                if (oldChangelog)
                {
                    changelog += `\n\n${oldChangelog}`;
                }

                await fs.writeFileAsync(changelogPath, changelog);

                updated = true;
            }
        }
    }
};

run(argv);