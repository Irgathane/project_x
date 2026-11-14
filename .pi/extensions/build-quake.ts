/**
 * build-quake — build pipeline tool for the slipgate QuakeC mod.
 *
 * Targets:
 *   progs  — compile QuakeC with fteqcc (slipgate/qc/progs.src -> progs.dat)
 *   map    — compile starter.map with qbsp/vis/light (ericw-tools)
 *   engine — (re)build vkQuake from source with meson/ninja + LunarG SDK env
 *   launch — run the locally built vkquake with -game slipgate +map starter
 *   all    — progs + map (map is skipped gracefully if ericw-tools missing)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type, type Static } from "typebox";
import { existsSync } from "node:fs";

const params = Type.Object({
	target: StringEnum(["progs", "map", "engine", "launch", "all"] as const, {
		description: "Which part of the pipeline to run",
	}),
	map: Type.Optional(Type.String({ description: "Map name without .map (default: starter)" })),
});
type Params = Static<typeof params>;

// LunarG Vulkan SDK env: Debian's vulkan loader/spirv-tools are too old for vkQuake.
const SDK = `${process.env.HOME}/VulkanSDK/1.4.363.1`;
const SDK_ENV = `export VULKAN_SDK="${SDK}/x86_64"; export PATH="${SDK}/x86_64/bin:$PATH"; export PKG_CONFIG_PATH="${SDK}/x86_64/lib/VulkanLoader/lib/pkgconfig:${SDK}/x86_64/share/pkgconfig:${SDK}/x86_64/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"; export LD_LIBRARY_PATH="${SDK}/x86_64/lib/VulkanLoader/lib:${SDK}/x86_64/lib:\${LD_LIBRARY_PATH:-}"`;

const MAX_OUTPUT = 4000; // chars of command output returned to the model

function tail(text: string, max = MAX_OUTPUT): string {
	return text.length > max ? `...[truncated]...\n${text.slice(-max)}` : text;
}

type Step = { name: string; code: number; output: string };

export default function buildQuake(pi: ExtensionAPI) {
	async function sh(script: string, cwd: string, signal?: AbortSignal) {
		return pi.exec("bash", ["-c", script], { cwd, signal });
	}

	pi.registerTool({
		name: "build_quake",
		label: "Build Quake",
		description:
			"Build pipeline for the slipgate QuakeC mod: 'progs' compiles QuakeC (fteqcc), 'map' compiles starter.map (qbsp/vis/light), 'engine' builds vkQuake from source (meson/ninja), 'launch' runs the locally built vkQuake, 'all' does progs+map. Returns exit code and the tail of the build output.",
		promptSnippet: "build_quake: compile QuakeC progs, maps, or the vkQuake engine, and launch the game",
		promptGuidelines: [
			"Use build_quake with target 'progs' after editing any .qc file, then report compiler warnings/errors verbatim (tail).",
			"Use build_quake with target 'map' only after editing .map or .wad files; it is skipped automatically if ericw-tools are absent.",
			"Use build_quake with target 'launch' to run the game for the user; never try to launch vkQuake via bash.",
		],
		parameters: params,
		async execute(_toolCallId, p: Params, signal, _onUpdate, ctx) {
			const root = ctx.cwd;
			const map = (p.map ?? "starter").replace(/\.map$/, "");
			const steps: Step[] = [];

			const record = (name: string, code: number, output: string) => {
				steps.push({ name, code, output: tail(output) });
				return code === 0;
			};

			// --- progs: fteqcc (+ ABI crc stamp, required by vkQuake) ---
			const buildProgs = async () => {
				const qc = `${root}/slipgate/qc`;
				const qcc = existsSync(`${root}/tools/fteqcc`) ? `${root}/tools/fteqcc` : "fteqcc";
				const r = await sh(`command -v "${qcc}" >/dev/null || { echo "ERROR: fteqcc not found in PATH or tools/"; exit 127; }; "${qcc}" progs.src`, qc, signal);
				if (r.code === 0) {
					// fteqcc's computed crc never equals PROGHEADER_CRC once a mod adds
					// fields, so stamp the vanilla marker or vkQuake refuses to load it.
					const stamp = await sh(`python3 "${root}/tools/fix_progs_crc.py" "${qc}/progs.dat"`, root, signal);
					await sh(`cp "${qc}/progs.dat" "${root}/slipgate/progs.dat"`, root, signal);
					record("progs", 0, `${r.stdout}${r.stderr}\n${stamp.stdout}\nprogs.dat copied to slipgate/`);
				} else {
					record("progs", r.code, `${r.stdout}\n${r.stderr}`);
				}
			};

			// --- map: qbsp/vis/light ---
			const buildMap = async () => {
				const probe = await sh("command -v qbsp >/dev/null && command -v vis >/dev/null && command -v light >/dev/null", root, signal);
				if (probe.code !== 0) {
					record(
						"map",
						-1,
						"SKIPPED: qbsp/vis/light (ericw-tools) not found in PATH.\nInstall: https://github.com/ericwa/ericw-tools/releases\nMap compile only needed after editing starter.map or slipgate.wad.",
					);
					return;
				}
				const r = await sh(`cd "${root}/slipgate/maps" && qbsp -wadpath . "${map}.map" && vis "${map}.bsp" && light "${map}.bsp"`, root, signal);
				record("map", r.code, `${r.stdout}\n${r.stderr}`);
			};

			// --- engine: meson/ninja with LunarG SDK ---
			const buildEngine = async () => {
				const vq = `${root}/vkQuake`;
				if (!existsSync(`${vq}/build/build.ninja`)) {
					const setup = await sh(`${SDK_ENV} && cd "${vq}" && meson setup build`, root, signal);
					if (!record("engine-setup", setup.code, `${setup.stdout}\n${setup.stderr}`)) return;
				}
				const r = await sh(`${SDK_ENV} && ninja -C "${vq}/build"`, root, signal);
				record("engine", r.code, `${r.stdout}\n${r.stderr}`);
			};

			// --- launch: locally built vkquake, basedir = repo root (./id1 + ./slipgate) ---
			const launch = async () => {
				const r = await sh(
					`${SDK_ENV} && cd "${root}" && exec "${root}/vkQuake/build/vkquake" -game slipgate +map "${map}"`,
					root,
					signal,
				);
				record("launch", r.code, `${r.stdout}\n${r.stderr}`);
			};

			if (p.target === "progs") await buildProgs();
			else if (p.target === "map") await buildMap();
			else if (p.target === "engine") await buildEngine();
			else if (p.target === "launch") await launch();
			else {
				// all: progs then map; stop if progs fails
				await buildProgs();
				if (steps.every((s) => s.code === 0 || s.code === -1)) await buildMap();
			}

			const failed = steps.filter((s) => s.code !== 0 && s.code !== -1);
			const ok = failed.length === 0;
			const summary = steps.map((s) => `## ${s.name} (exit ${s.code})\n${s.output.trim()}`).join("\n\n");
			return {
				content: [{ type: "text", text: ok ? summary : `BUILD FAILED:\n${summary}` }],
				details: { steps, ok },
				isError: !ok,
			};
		},
	});
}
