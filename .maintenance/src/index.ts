import * as yargs from "yargs";
import { Manager } from "./manager";
import { update } from "./commands/update";
import { run } from "./commands/run";
import { build } from "./commands/build";

const manager = new Manager();

const argv = yargs
    .command(["update", "$0"], "performs addon updates", (args) =>
    {
        return args
            .option("patch", {
                alias: "p",
                default: false,
                boolean: true
            });
    }, (opts) =>
    {
        update(manager, opts);
    })
    .command("run <addon>", "runs an addon", (argv) =>
        argv
            .option("clean", { alias: "c", default: false, boolean: true })
            .option("nobuild", { alias: "n", default: false, boolean: true }),
        (opts) =>
        {
            run(manager, opts);
        })
    .command("build <addon>", "builds an addon", (argv) =>
        argv
            .option("nocheck", { alias: "n", default: false, boolean: true }),
        (opts) =>
        {
            build(manager, opts);
        })
    .argv;


