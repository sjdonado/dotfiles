import { type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const Params = Type.Object({
	name: Type.String({ description: "New session display name" }),
});

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "set_session_name",
		label: "Set session name",
		description:
			"Set the current session's display name (shown in the session selector). Use to label a session, e.g. by ticket id and title.",
		promptSnippet: "set_session_name(name) — rename the current session",
		parameters: Params,
		async execute(_id, params, _signal, _onUpdate, ctx) {
			ctx.setSessionName(params.name);
			return {
				content: [{ type: "text", text: `Session renamed to: ${params.name}` }],
				details: { name: params.name },
			};
		},
	});
}
