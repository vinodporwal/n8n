<script setup lang="ts">
import { reactive, computed, toRefs } from 'vue';
import type { ActionTypeDescription, SimplifiedNodeType } from '@/Interface';
import { WEBHOOK_NODE_TYPE, DRAG_EVENT_DATA_KEY } from '@/constants';

import { DEFAULT_NODE_SIZE, getNewNodePosition } from '@/utils/nodeViewUtils';
import NodeIcon from '@/components/NodeIcon.vue';

import { useViewStacks } from '../composables/useViewStacks';
import { useActions } from '../composables/useActions';
import { useTelemetry } from '@/composables/useTelemetry';

export interface Props {
	nodeType: SimplifiedNodeType;
	action: ActionTypeDescription;
}

const props = defineProps<Props>();
const telemetry = useTelemetry();

const { getActionData, getAddedNodesAndConnections, setAddedNodeActionParameters } = useActions();
const { activeViewStack } = useViewStacks();

const state = reactive({
	dragging: false,
	draggablePosition: {
		x: -100,
		y: -100,
	},
	storeWatcher: null as Function | null,
	draggableDataTransfer: null as Element | null,
});

const draggableStyle = computed<{ top: string; left: string }>(() => ({
	top: `${state.draggablePosition.y}px`,
	left: `${state.draggablePosition.x}px`,
}));

const actionData = computed(() => getActionData(props.action));

const isTriggerAction = (action: ActionTypeDescription) =>
	action.name?.toLowerCase().includes('trigger') || action.name === WEBHOOK_NODE_TYPE;

function onDragStart(event: DragEvent): void {
	/**
	 * Workaround for firefox, that doesn't attach the pageX and pageY coordinates to "ondrag" event.
	 * All browsers attach the correct page coordinates to the "dragover" event.
	 * @bug https://bugzilla.mozilla.org/show_bug.cgi?id=505521
	 */
	document.body.addEventListener('dragover', onDragOver);
	const { pageX: x, pageY: y } = event;
	if (event.dataTransfer && actionData.value.key) {
		event.dataTransfer.effectAllowed = 'copy';
		event.dataTransfer.dropEffect = 'copy';
		event.dataTransfer.setDragImage(state.draggableDataTransfer as Element, 0, 0);
		event.dataTransfer.setData(
			DRAG_EVENT_DATA_KEY,
			JSON.stringify(getAddedNodesAndConnections([{ type: actionData.value.key }])),
		);
		if (telemetry) {
			state.storeWatcher = setAddedNodeActionParameters(
				actionData.value,
				telemetry,
				activeViewStack.rootView,
			);
		}
		document.body.addEventListener('dragend', onDragEnd);
	}

	state.dragging = true;
	state.draggablePosition = { x, y };
}

function onDragOver(event: DragEvent): void {
	if (!state.dragging || (event.pageX === 0 && event.pageY === 0)) {
		return;
	}

	const [x, y] = getNewNodePosition(
		[],
		[event.pageX - DEFAULT_NODE_SIZE[0] / 2, event.pageY - DEFAULT_NODE_SIZE[1] / 2],
	);

	state.draggablePosition = { x, y };
}

function onDragEnd(): void {
	if (state.storeWatcher) state.storeWatcher();
	document.body.removeEventListener('dragend', onDragEnd);
	document.body.removeEventListener('dragover', onDragOver);

	state.dragging = false;
	setTimeout(() => {
		state.draggablePosition = { x: -100, y: -100 };
	}, 300);
}
const { draggableDataTransfer, dragging } = toRefs(state);
</script>

<template>
	<n8n-node-creator-node
		draggable
		:class="$style.action"
		:title="action.displayName"
		:is-trigger="isTriggerAction(action)"
		data-keyboard-nav="true"
		@dragstart="onDragStart"
		@dragend="onDragEnd"
	>
		<template #dragContent>
			<div ref="draggableDataTransfer" :class="$style.draggableDataTransfer" />
			<div v-show="dragging" :class="$style.draggable" :style="draggableStyle">
				<NodeIcon :node-type="nodeType" :size="40" :shrink="false" @click.capture.stop />
			</div>
		</template>
		<template #icon>
			<NodeIcon :node-type="action" />
		</template>
	</n8n-node-creator-node>
</template>

<style lang="scss" module>
.action {
	--node-creator-name-size: var(--font-size-2xs);
	--node-creator-name-weight: var(--font-weight-normal);
	--trigger-icon-background-color: #{$trigger-icon-background-color};
	--trigger-icon-border-color: #{$trigger-icon-border-color};
	--node-icon-size: 20px;
	--node-icon-margin-right: var(--spacing-xs);

	margin-left: var(--spacing-s);
	margin-right: var(--spacing-s);
	padding: var(--spacing-2xs) 0;
}
.nodeIcon {
	margin-right: var(--spacing-xs);
}

.draggable {
	width: 100px;
	height: 100px;
	position: fixed;
	z-index: 1;
	opacity: 0.66;
	border: 2px solid var(--color-foreground-xdark);
	border-radius: var(--border-radius-large);
	background-color: var(--color-background-xlight);
	display: flex;
	justify-content: center;
	align-items: center;
}

.draggableDataTransfer {
	width: 1px;
	height: 1px;
}
</style>
