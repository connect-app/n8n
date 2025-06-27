# Product Requirements Document (PRD)

## Проект: Расширение OpenAI Chat Model Node в n8n

**Версия:** 1.0  
**Дата создания:** 2025-01-28  
**Автор:** Development Team  
**Статус:** Draft  

---

## 📋 **Обзор проекта**

### **Цель продукта**
Расширить функциональность OpenAI Chat Model Node для поддержки современных возможностей OpenAI API, включая контроль стриминга и структурированные ответы через JSON Schema.

### **Целевая аудитория**
- Разработчики n8n воркфлоу
- AI/ML инженеры
- Автоматизационные специалисты
- DevOps инженеры

### **Проблема**
Текущая реализация OpenAI Chat Model Node не предоставляет:
1. Контроль над потоковым режимом (streaming всегда включен)
2. Поддержку JSON Schema для структурированных ответов
3. Современные возможности OpenAI API для точного контроля формата ответов

---

## 🎯 **Продуктовые требования**

### **PR-001: Контроль потокового режима**

**Как пользователь я хочу:**
- Явно управлять режимом streaming для OpenAI модели
- Отключать streaming для случаев, где нужен полный ответ сразу
- Видеть четкую индикацию текущего режима

**Критерии приемки:**
- ✅ Новая опция "Streaming" в существующей секции Options
- ✅ По умолчанию streaming отключен (false) для обратной совместимости
- ✅ Опция влияет на поведение API вызовов
- ✅ Совместимость с существующими воркфлоу

**Пользовательский сценарий:**
```
ДАНО: Пользователь создает новый OpenAI Chat Model нод
КОГДА: Пользователь открывает настройки Options
ТОГДА: Видит опцию "Streaming" с значениями Enable/Disable
И: По умолчанию выбрано "Disable"
```

### **PR-002: Поддержка JSON Schema**

**Как пользователь я хочу:**
- Задавать точную структуру ответа через JSON Schema
- Получать гарантированно структурированные ответы от AI
- Валидировать корректность введенной схемы

**Критерии приемки:**
- ✅ Расширена опция "Response Format" с новым типом "JSON Schema"
- ✅ Поле для ввода JSON Schema в существующей секции Options
- ✅ Валидация корректности JSON Schema при сохранении нода
- ✅ Четкая обработка ошибок - показать ошибку, если модель не поддерживает JSON Schema
- ✅ Интеграция с OpenAI Structured Outputs API
- ✅ Примеры популярных схем

**Пользовательский сценарий:**
```
ДАНО: Пользователь выбрал Response Format = "JSON Schema"
КОГДА: Появляется поле "JSON Schema"
ТОГДА: Пользователь вводит валидную JSON схему
И: Получает структурированный ответ согласно схеме
И: Видит ошибку при невалидной схеме
```

### **PR-003: Улучшенный пользовательский опыт**

**Как пользователь я хочу:**
- Интуитивно понимать назначение новых опций
- Видеть примеры и подсказки
- Легко мигрировать существующие воркфлоу

**Критерии приемки:**
- ✅ Подробные описания для новых опций в существующей секции Options
- ✅ Условное отображение полей (JSON Schema только при выборе соответствующего формата)
- ✅ Валидация при сохранении с понятными сообщениями об ошибках
- ✅ Примеры JSON Schema в описании
- ✅ Миграция существующих нодов без потери функциональности

---

## 🔧 **Технические спецификации**

### **TS-001: Архитектура изменений**

**Файл:** `LmChatOpenAi.node.ts`

**Новые типы:**
```typescript
interface StreamingOptions {
  streaming?: boolean;
  responseFormat?: 'text' | 'json_object' | 'json_schema';
  jsonSchema?: string;
}

type ResponseFormatType = 'text' | 'json_object' | 'json_schema';

interface JsonSchemaFormat {
  type: 'json_schema';
  json_schema: {
    name: string;
    schema: object;
    strict?: boolean;
  };
}
```

**Изменения в UI:**
```typescript
// Новая опция Streaming (в существующей секции Options)
{
  displayName: 'Streaming',
  name: 'streaming',
  type: 'boolean',
  default: false,
  description: 'Enable streaming mode for real-time response generation. Disabled by default for compatibility.',
}

// Расширенная опция Response Format
{
  displayName: 'Response Format',
  name: 'responseFormat',
  type: 'options',
  options: [
    { name: 'Text', value: 'text' },
    { name: 'JSON Object', value: 'json_object' },
    { name: 'JSON Schema', value: 'json_schema' }
  ]
}

// Поле JSON Schema (в существующей секции Options)
{
  displayName: 'JSON Schema',
  name: 'jsonSchema',
  type: 'json',
  default: '{"type": "object", "properties": {}}',
  displayOptions: {
    show: { responseFormat: ['json_schema'] }
  },
  description: 'Define the structure of the JSON response. Validated on save.',
  validateType: 'jsonSchema',
  placeholder: 'Enter valid JSON Schema...'
}
```

### **TS-002: Обработка параметров**

**Функция обработки response format:**
```typescript
function getResponseFormat(options: StreamingOptions): object | undefined {
  switch (options.responseFormat) {
    case 'json_object':
      return { type: 'json_object' };
    case 'json_schema':
      if (!options.jsonSchema) {
        throw new NodeOperationError(this.getNode(), 'JSON Schema is required when format is json_schema');
      }
      try {
        const schema = JSON.parse(options.jsonSchema);
        // Validate schema structure
        if (!schema.type) {
          throw new Error('JSON Schema must have a "type" field');
        }
        return {
          type: 'json_schema',
          json_schema: {
            name: 'custom_schema',
            schema,
            strict: true
          }
        };
      } catch (error) {
        throw new NodeOperationError(this.getNode(), `Invalid JSON Schema: ${error.message}`);
      }
    default:
      return undefined;
  }
}
```

### **TS-003: Интеграция с LangChain**

**Изменения в supplyData:**
```typescript
const model = new ChatOpenAI({
  // ... существующие параметры
  streaming: options.streaming ?? false,
  modelKwargs: {
    ...modelKwargs,
    ...(options.responseFormat && options.responseFormat !== 'text' 
      ? { response_format: getResponseFormat(options) } 
      : {})
  }
});
```

---

## 🧪 **Тестовые сценарии**

### **T-001: Функциональные тесты**

| ID | Сценарий | Ожидаемый результат |
|----|----------|-------------------|
| T-001-01 | Создание нода с streaming=false | Ответ приходит без стриминга |
| T-001-02 | Создание нода с streaming=true | Ответ приходит потоково |
| T-001-03 | JSON Schema с валидной схемой | Структурированный ответ |
| T-001-04 | JSON Schema с невалидной схемой | Ошибка валидации |
| T-001-05 | Миграция существующего нода | Работает без изменений |

### **T-002: Интеграционные тесты**

| ID | Сценарий | Компоненты |
|----|----------|------------|
| T-002-01 | Работа с AI Chain | LmChatOpenAi + AI Chain |
| T-002-02 | Работа с AI Agent | LmChatOpenAi + AI Agent |
| T-002-03 | Различные модели GPT | GPT-4, GPT-4o, GPT-4o-mini |

### **T-003: Производительность**

| Метрика | Целевое значение | Способ измерения |
|---------|------------------|------------------|
| Время ответа | ≤ +5% от текущего | Benchmark тесты |
| Память | ≤ +2% от текущего | Memory profiling |
| CPU | ≤ +1% от текущего | Performance tests |

---

## 📊 **Пользовательские истории**

### **Epic 1: Контроль стриминга**

**US-001:** Как разработчик воркфлоу, я хочу отключить streaming, чтобы получать полный ответ сразу для последующей обработки

**US-002:** Как системный администратор, я хочу контролировать режим стриминга, чтобы оптимизировать нагрузку на сервер

### **Epic 2: Структурированные ответы**

**US-003:** Как AI инженер, я хочу получать ответы в строго определенном JSON формате, чтобы интегрировать их с другими системами

**US-004:** Как разработчик, я хочу валидировать JSON Schema, чтобы избежать ошибок на продакшене

### **Epic 3: Удобство использования**

**US-005:** Как новый пользователь n8n, я хочу видеть примеры JSON Schema, чтобы быстро освоить новую функциональность

**US-006:** Как существующий пользователь, я хочу, чтобы мои воркфлоу продолжали работать после обновления

---

## 🚀 **План релиза**

### **Milestone 1: Core Functionality** (v1.3.0)
- ✅ Добавление streaming опции
- ✅ Базовая поддержка JSON Schema
- ✅ Обратная совместимость

### **Milestone 2: Enhanced UX** (v1.3.1)
- 📋 Примеры JSON Schema
- 📋 Улучшенная валидация
- 📋 Документация

### **Milestone 3: Optimization** (v1.3.2)
- 📋 Производительность
- 📋 Расширенные тесты
- 📋 Мониторинг

---

## 📈 **Метрики успеха**

### **Продуктовые метрики**
- Adoption Rate: >30% пользователей используют новые опции в течение 3 месяцев
- Error Rate: <1% ошибок связанных с новыми функциями
- User Satisfaction: >4.5/5 в отзывах

### **Технические метрики**
- Performance Impact: <5% degradation
- Test Coverage: >90% для новых функций
- Zero Breaking Changes для существующих воркфлоу

---

## 🔍 **Приложения**

### **A1: Примеры JSON Schema**

**Простой объект:**
```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string" },
    "age": { "type": "number" }
  },
  "required": ["name"]
}
```

**Массив объектов:**
```json
{
  "type": "object",
  "properties": {
    "users": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "email": { "type": "string", "format": "email" }
        }
      }
    }
  }
}
```

### **A2: Миграционная стратегия**

**Версия 1.2 → 1.3:**
- Существующие ноды: streaming = false (по умолчанию)
- responseFormat сохраняет текущие значения
- Никаких breaking changes

---

## ✅ **Чек-лист готовности к релизу**

### **Разработка**
- [ ] Код реализован согласно спецификации
- [ ] Code review пройден
- [ ] Все тесты проходят
- [ ] Performance тесты выполнены

### **Тестирование**
- [ ] Functional тесты
- [ ] Integration тесты
- [ ] User acceptance тесты
- [ ] Regression тесты

### **Документация**
- [ ] Техническая документация обновлена
- [ ] User guide создан
- [ ] API documentation обновлена
- [ ] Changelog подготовлен

### **Деплой**
- [ ] Staging тестирование завершено
- [ ] Production deployment план готов
- [ ] Rollback план подготовлен
- [ ] Monitoring настроен

---

## 🎯 **Принятые архитектурные решения**

### **Ключевые решения (зафиксированы):**
1. **Streaming по умолчанию:** `false` - для обратной совместимости
2. **JSON Schema валидация:** При сохранении нода (не в реальном времени)
3. **Размещение в UI:** В существующей секции "Options"
4. **Обработка ошибок:** Показать ошибку и остановить выполнение, если модель не поддерживает JSON Schema

### **Технические детали:**
- Использовать `NodeOperationError` для четких сообщений об ошибках
- JSON Schema с обязательным полем `type`
- Валидация структуры схемы перед отправкой в OpenAI
- По умолчанию `{"type": "object", "properties": {}}` для JSON Schema

---

**Контакты для вопросов:**
- Product Owner: [имя]
- Tech Lead: [имя]  
- QA Lead: [имя] 