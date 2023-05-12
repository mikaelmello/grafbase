import { g, config } from '@grafbase/sdk'

const user = g.model("User", {
  name: g.string().length({ min: 1, max: 255 }),
  age: g.int().optional()
})

export default config().schema({ models: [user] })