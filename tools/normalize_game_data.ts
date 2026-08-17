import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import { dirname, extname, join, relative, resolve } from "node:path";

type JsonObject = { [key: string]: JsonValue };
type JsonValue = null | boolean | number | string | JsonValue[] | JsonObject;

const [inputArgument, outputArgument] = process.argv.slice(2);
if (!inputArgument || !outputArgument) {
    console.error("usage: bun tools/normalize_game_data.ts <input-dir> <output-dir>");
    process.exit(1);
}

const inputRoot = resolve(inputArgument);
const outputRoot = resolve(outputArgument);
if (inputRoot === outputRoot) {
    console.error("input and output directories must be different");
    process.exit(1);
}

let copied = 0;
let normalized = 0;

await walk(inputRoot);
console.log(`normalized ${normalized} ID maps; copied ${copied} other JSON files`);

async function walk(directory: string): Promise<void> {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
        const path = join(directory, entry.name);
        if (entry.isDirectory()) {
            await walk(path);
        } else if (entry.isFile() && extname(entry.name).toLowerCase() === ".json") {
            await normalizeFile(path);
        }
    }
}

async function normalizeFile(inputPath: string): Promise<void> {
    const source = await readFile(inputPath, "utf8");
    let data: JsonValue;
    try {
        data = JSON.parse(source) as JsonValue;
    } catch (error) {
        throw new Error(`invalid JSON in ${inputPath}: ${String(error)}`);
    }

    const result = normalizeRootIdMap(data);
    const outputPath = join(outputRoot, relative(inputRoot, inputPath));
    await mkdir(dirname(outputPath), { recursive: true });
    await writeFile(outputPath, `${JSON.stringify(result.data, null, 2)}\n`);

    if (result.wasNormalized) normalized += 1;
    else copied += 1;
}

/**
 * Converts only a root object whose every value is an object with an `Id`
 * equal to its key. Empty objects are retained: without records, there is no
 * evidence that they are ID maps.
 */
function normalizeRootIdMap(data: JsonValue): { data: JsonValue; wasNormalized: boolean } {
    if (!isObject(data) || Array.isArray(data)) return { data, wasNormalized: false };

    const entries = Object.entries(data);
    if (entries.length === 0) return { data, wasNormalized: false };
    if (!entries.every(([key, value]) => isIdRecord(key, value)))
        return { data, wasNormalized: false };

    // Numeric keys are sorted explicitly so generated diffs are deterministic.
    entries.sort(([left], [right]) => Number(left) - Number(right));
    return { data: entries.map(([, value]) => value), wasNormalized: true };
}

function isIdRecord(key: string, value: JsonValue): value is JsonObject {
    if (!isObject(value) || Array.isArray(value) || !("Id" in value)) return false;

    const id = value.Id;
    return (typeof id === "number" && Number.isSafeInteger(id) && String(id) === key) ||
        (typeof id === "string" && id === key);
}

function isObject(value: JsonValue): value is JsonObject {
    return typeof value === "object" && value !== null;
}
