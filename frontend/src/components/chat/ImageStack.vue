<template>
  <div
    class="relative"
    :style="{ width: cardDimensions.width + 'px', height: cardDimensions.height + 'px', perspective: '600px' }"
  >
    <template v-for="(card, index) in cards" :key="card.id">
      <Motion
        as="div"
        class="absolute cursor-grab"
        :style="{
          x: cardStates.get(card.id)?.x,
          y: cardStates.get(card.id)?.y,
          rotateX: cardStates.get(card.id)?.rotateX,
          rotateY: cardStates.get(card.id)?.rotateY
        }"
        drag
        :drag-constraints="{ top: 0, right: 0, bottom: 0, left: 0 }"
        :dragElastic="0.6"
        :whileTap="{ cursor: 'grabbing', scale: 1.02 }"
        :onDragEnd="(e: PointerEvent, info: PanInfo) => handleDragEnd(e, info, card.id)"
      >
        <Motion
          as="div"
          class="rounded-2xl overflow-hidden border-4 border-white shadow-lg"
          @click="handleClick(card)"
          :animate="{
            rotateZ: (cards.length - index - 1) * 4 + (randomRotation ? Math.random() * 10 - 5 : 0),
            scale: 1 + index * 0.06 - cards.length * 0.06,
            transformOrigin: '90% 90%'
          }"
          :initial="false"
          :transition="{
            type: 'spring',
            stiffness: animationConfig.stiffness,
            damping: animationConfig.damping
          }"
          :style="{
            width: cardDimensions.width + 'px',
            height: cardDimensions.height + 'px'
          }"
        >
          <img :src="card.img" :alt="`card-${card.id}`" class="w-full h-full object-cover pointer-events-none" />
        </Motion>
      </Motion>
    </template>
  </div>
</template>

<script setup lang="ts">
import type { PanInfo } from 'motion-v';
import { Motion, useMotionValue, useTransform } from 'motion-v';
import { onBeforeMount, ref, watch } from 'vue';

interface CardData {
  id: number;
  img: string;
}

interface Props {
  randomRotation?: boolean;
  sensitivity?: number;
  cardDimensions?: { width: number; height: number };
  cardsData: CardData[];
  animationConfig?: { stiffness: number; damping: number };
  sendToBackOnClick?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  randomRotation: true,
  sensitivity: 180,
  cardDimensions: () => ({ width: 200, height: 200 }),
  cardsData: () => [],
  animationConfig: () => ({ stiffness: 260, damping: 20 }),
  sendToBackOnClick: true
});

const emit = defineEmits<{
  (e: 'cardClick', card: CardData): void;
}>();

const cards = ref<CardData[]>([...props.cardsData]);

// 监听 props 变化
watch(() => props.cardsData, (newData) => {
  cards.value = [...newData];
  // 为新卡片创建状态
  newData.forEach(card => {
    if (!cardStates.has(card.id)) {
      cardStates.set(card.id, createCardState());
    }
  });
}, { deep: true });

type CardState = {
  x: ReturnType<typeof useMotionValue<number>>;
  y: ReturnType<typeof useMotionValue<number>>;
  rotateX: ReturnType<typeof useMotionValue<number>>;
  rotateY: ReturnType<typeof useMotionValue<number>>;
  reset: () => void;
};

const cardStates = new Map<number, CardState>();

function createCardState(): CardState {
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  const rotateX = useTransform(y, [-100, 100], [60, -60]);
  const rotateY = useTransform(x, [-100, 100], [-60, 60]);

  return {
    x,
    y,
    rotateX,
    rotateY,
    reset() {
      x.set(0);
      y.set(0);
    }
  };
}

onBeforeMount(() => {
  cards.value.forEach(card => {
    if (!cardStates.has(card.id)) {
      cardStates.set(card.id, createCardState());
    }
  });
});

function getCardState(cardId: number): CardState {
  let state = cardStates.get(cardId);
  if (!state) {
    state = createCardState();
    cardStates.set(cardId, state);
  }
  return state;
}

function handleDragEnd(_: PointerEvent, info: PanInfo, cardId: number) {
  if (Math.abs(info.offset.x) > props.sensitivity || Math.abs(info.offset.y) > props.sensitivity) {
    sendToBack(cardId);
  } else {
    getCardState(cardId).reset();
  }
}

const sendToBack = (id: number) => {
  const newCards = [...cards.value];
  const index = newCards.findIndex(card => card.id === id);
  if (index === -1) return;
  const [card] = newCards.splice(index, 1);
  if (card) newCards.unshift(card);
  cards.value = newCards;
};

const handleClick = (card: CardData) => {
  if (props.sendToBackOnClick) {
    sendToBack(card.id);
  }
  emit('cardClick', card);
};
</script>
