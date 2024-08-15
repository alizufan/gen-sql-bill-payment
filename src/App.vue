<script setup lang="ts">
import * as XLSX from 'xlsx'
import { onBeforeMount, reactive, ref } from 'vue'
import {
  ElMessage,
  type UploadFile,
  type UploadInstance
} from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'

const quotes = ref<string>('')

document.title = "Gen SQL Import"

onBeforeMount(async () => {
  try {
    const resp = await fetch('https://dummyjson.com/quotes/random')
    const json = await resp.json()
    quotes.value = `"${json.quote}" - ${json.author}`
  } catch (err: any) {
    console.error(err)
  }
})

type IMetadata = {
  [key: number]: {
    sheet: string
    headers: string[]
  }
}

type SheetParatamerInput = {
  secondaryCategoryCode: string
  aggregator: string
  biller: string
}

type SheetProductInput = {
  secondaryCategoryCode: string
  biller: string
  transactionTypeCode: string
  productName: string
  productId: string
  aggregator: string
  sortNo: number
  isPointEnabled: 'Y' | 'N'
  isAdminFeeEnabled: 'Y' | 'N'
  adminFee: number
  serviceFee: number
  commissionFee: number
  channelFee: number
  productLogoUrl: string
  mobilePrefixPattern: string
  isValid: 'Y' | 'N'
}

type SheetProductDetailInput = {
  billProductId: string
  type: string
  value: string
  isValid: 'Y' | 'N'
}

type SheetProductCategoryInput = {
  secondaryCategoryCode: string
  aggregator: string
  productCategoryCode: string
  countryCode: string
  variant: string
  name: string
  description: string
  isValid: 'Y' | 'N'
}

type SheetProductCategoryFormInput = {
  secondaryCategoryCode: string
  productCategoryCode: string
  aggregator: string
  formKey: string
  formType: string
  formCondition: string
  pattrenCondition: string
  formLabel: {
    [key: string]: string
  }
  description: {
    [key: string]: string
  }
  options: {
    [key: string]: {
      label: string
      description: string
      option: string
    }[]
  }
  sortNo: number
  isValid: 'Y' | 'N'
}

type ImportSheetInput = {
  paramaters: SheetParatamerInput
  products: SheetProductInput[]
  productDetails: SheetProductDetailInput[]
  productCategories: SheetProductCategoryInput[]
  productCategoryForms: SheetProductCategoryFormInput[]
}

const sheetMetadatas: IMetadata = {
  0: {
    sheet: 'Import-Paramater',
    headers: ['secondary_category_code', 'aggregator', 'biller']
  },
  1: {
    sheet: 'Product',
    headers: [
      'biller',
      'transaction_type',
      'product_id',
      'product_name',
      'product_logo',
      'mobile_prefix_pattren',
      'sort_no',
      'is_point_enabled',
      'is_admin_fee_enabled',
      'admin_fee',
      'service_fee',
      'commission_fee',
      'channel_fee',
      'is_valid'
    ]
  },
  2: {
    sheet: 'Product-Detail',
    headers: ['product_id', 'detail_key', 'detail_value', 'is_valid']
  },
  3: {
    sheet: 'Product-Category',
    headers: ['product_category_code', 'country_code', 'variant', 'name', 'description', 'is_valid']
  },
  4: {
    sheet: 'Product-Form-Input',
    headers: [
      'lang',
      'sort_no',
      'product_category_code',
      'form_key',
      'form_type',
      'form_label',
      'form_desc',
      'form_pattern_validation',
      'form_condition',
      'is_valid'
    ]
  },
  5: {
    sheet: 'Product-Form-Input-Option',
    headers: [
      'lang',
      'product_category_code',
      'form_key',
      'option_value',
      'option_label',
      'option_description'
    ]
  }
}

const importSheetMasterData = reactive<{ [key: string]: any[] }>({})
const importFilename = ref<string>('')
const workbook = ref<XLSX.WorkBook>()
const uploadImportRef = ref<UploadInstance>()

const onChangeImportFile = async (f: UploadFile) => {
  resetImportFiles()
  if (!f.raw) return
  if (
    !['.xlxs', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'].includes(
      f.raw.type
    )
  ) {
    ElMessage.error('Unsupported Import File Type')
    return
  }

  const file = await f.raw.arrayBuffer()
  importFilename.value = f.raw.name
  workbook.value = XLSX.read(file)
  const sheetNames = workbook.value.SheetNames

  for (let i = 0; i < sheetNames.length; i++) {
    const sheetName = sheetNames[i]
    const sheetMetadata = sheetMetadatas[i]
    if (sheetName !== sheetMetadata.sheet) continue

    const worksheet = workbook.value.Sheets[sheetName]
    const jsons = XLSX.utils.sheet_to_json<string[]>(worksheet, {
      header: 1
    })

    importSheetMasterData[sheetName] = jsons
      .filter((_, idx) => idx !== 0)
      .filter((v) => v.length > 0)
      .map((v) => {
        let merge = {}
        const mapper = v.map((val, idx) => ({
          [sheetMetadata.headers[idx]]: val
        }))

        for (let j = 0; j < mapper.length; j++) {
          const obj = mapper[j]
          merge = { ...merge, ...obj }
        }

        return merge
      })
  }
}

const submitImportFile = () => {
  const input: ImportSheetInput = {
    paramaters: {
      secondaryCategoryCode: '',
      aggregator: '',
      biller: ''
    },
    products: [],
    productDetails: [],
    productCategories: [],
    productCategoryForms: []
  }

  const keys = Object.keys(importSheetMasterData)
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i]
    const array = importSheetMasterData[key]
    if (key === 'Import-Paramater') {
      input.paramaters = {
        secondaryCategoryCode: array[0].secondary_category_code,
        aggregator: array[0].aggregator,
        biller: array[0].biller
      }
      continue
    }

    if (key === 'Product') {
      input.products = array.map<SheetProductInput>((v) => ({
        secondaryCategoryCode: input.paramaters.secondaryCategoryCode,
        aggregator: input.paramaters.aggregator,
        biller: v.biller,
        transactionTypeCode: v.transaction_type,
        productName: v.product_name,
        productId: v.product_id,
        sortNo: v.sort_no,
        isPointEnabled: v.is_point_enabled,
        isAdminFeeEnabled: v.is_admin_fee_enabled,
        adminFee: parseInt(String(v.admin_fee).trim()),
        serviceFee: parseInt(String(v.service_fee).trim()),
        commissionFee: parseInt(String(v.commission_fee).trim()),
        channelFee: parseInt(String(v.channel_fee).trim()),
        productLogoUrl: v.product_logo,
        mobilePrefixPattern: v.mobile_prefix_pattren ?? null,
        isValid: v.is_valid
      }))
      continue
    }

    if (key === 'Product-Detail') {
      input.productDetails = array.map<SheetProductDetailInput>((v) => ({
        billProductId: v.product_id,
        type: v.detail_key,
        value: v.detail_value,
        isValid: v.is_valid
      }))
      continue
    }

    if (key === 'Product-Category') {
      input.productCategories = array.map<SheetProductCategoryInput>((v) => ({
        secondaryCategoryCode: input.paramaters.secondaryCategoryCode,
        aggregator: input.paramaters.aggregator,
        productCategoryCode: v.product_category_code,
        countryCode: v.country_code,
        variant: v.variant,
        name: v.name,
        description: v.description,
        isValid: v.is_valid
      }))
      continue
    }

    if (key === 'Product-Form-Input') {
      // # convert array form options to map
      const formOptionMaps = importSheetMasterData['Product-Form-Input-Option'].reduce(
        (obj, item) => {
          const {
            lang,
            product_category_code,
            form_key,
            option_value,
            option_label,
            option_description
          } = item
          const keyReduce = `${lang}|${form_key}|${product_category_code}`
          if (!Array.isArray(obj[keyReduce])) {
            obj[keyReduce] = []
          }
          obj[keyReduce].push({
            label: option_label,
            option: option_value,
            description: option_description
          })
          return obj
        },
        {}
      )

      // # convert array forms to map
      const forms = array.reduce((obj, item) => {
        const { product_category_code, form_key } = item
        const keyReduce = `${form_key}|${product_category_code}`
        if (!Array.isArray(obj[keyReduce])) {
          obj[keyReduce] = []
        }
        obj[keyReduce].push(item)
        return obj
      }, {})

      // # form data mapper
      const formData = []
      const formsKeys = Object.keys(forms)
      for (let idx = 0; idx < formsKeys.length; idx++) {
        // # paramaters
        const { aggregator, secondaryCategoryCode } = input.paramaters

        // # init
        let label: { [key: string]: string } = {}
        let description: { [key: string]: string } = {}
        let options: { [key: string]: any[] } = {}

        // # mapper
        const form = forms[formsKeys[idx]]
        for (let j = 0; j < form.length; j++) {
          const elem = form[j]

          // # label
          label[elem.lang] = elem.form_label

          // # description
          description[elem.lang] = elem.description ?? ''

          // # option
          const keyOption = `${elem.lang}|${elem.form_key}|${elem.product_category_code}`
          options[elem.lang] = formOptionMaps[keyOption] ?? []
        }

        // # final processing
        const mapped = {
          secondaryCategoryCode,
          productCategoryCode: form.at(0).product_category_code as string,
          aggregator,
          formKey: form.at(0).form_key as string,
          formLabel: label as { [key: string]: string },
          formType: form.at(0).form_type as string,
          formCondition: form.at(0).form_condition as string,
          pattrenCondition: (form.at(0).form_pattern_validation as string) ?? null,
          options: options as { [key: string]: any[] },
          description: description as { [key: string]: string },
          sortNo: (form.at(0).sortNo as number) ?? 1,
          isValid: form.at(0).is_valid as 'Y' | 'N'
        }

        formData.push(mapped)
      }

      input.productCategoryForms = formData
      continue
    }
  }
  const product = input.products.map(v => {
    return [
      "insert into `t_bill_product` (`admin_fee`, `aggregator`, `biller`, `channel_fee`, `commission_fee`, `created_by`, `created_time`, `is_admin_fee_enabled`, `is_point_enabled`, `is_valid`, `mobile_prefix_pattern`, `product_id`, `product_logo_url`, `product_name`, `secondary_category_code`, `service_fee`, `sort_no`, `transaction_type_code`, `updated_by`, `updated_time`) values",
      "('" + v.adminFee.toFixed(2) + "', '" + v.aggregator + "', '" + v.biller + "', '0.00', '" + v.commissionFee.toFixed(2) + "', 'system', CURRENT_TIMESTAMP, 'Y', 'N', '" + v.isValid + "', NULL, '" + v.productId + "', '" + (v.productLogoUrl || '') + "', '" + (v.productName || '') + "', '" + v.secondaryCategoryCode + "', '0.00', '" + v.sortNo + "', '" + v.transactionTypeCode + "', 'system', CURRENT_TIMESTAMP);"
    ].join(" ")
  })
  productSQL.value = product.join('\n');
  (() => {
    const blob = new Blob([productSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "insert-new-product.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  const productDetail = input.productDetails.map(v => {
    let value = v.value
    const val = parseInt(value)
    if (!isNaN(val)) {
      value = val.toFixed(2)
    }
    return [
      "insert into `t_bill_product_detail` (`bill_product_id`, `is_valid`, `type`, `value`) values",
      "('" + v.billProductId + "', '" + v.isValid + "', '" + v.type + "', '" + value + "');"
    ].join(" ")
  })
  productDetailSQL.value = productDetail.join('\n');

  (() => {
    const blob = new Blob([productDetailSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "insert-new-product-detail.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  const forms = input.productCategoryForms.map(v => {
    return [
      "insert into `t_bill_product_category_form` (`aggregator`, `created_by`, `created_time`, `description`, `form_condition`, `form_key`, `form_type`, `is_valid`, `label`, `more_info`, `options`, `pattern_validation`, `product_category_code`, `secondary_category_code`, `sort_no`, `updated_by`, `updated_time`) values",
      "('" + v.aggregator + "', 'system', CURRENT_TIMESTAMP, '" + JSON.stringify(v.description) + "', '" + v.formCondition + "', '" + v.formKey + "', '" + v.formType + "', '" + v.isValid + "', '" + JSON.stringify(v.formLabel) + "', NULL, '" + JSON.stringify(v.options) + "', NULL, '" + v.productCategoryCode + "', '" + v.secondaryCategoryCode + "', '" + v.sortNo + "', 'system', CURRENT_TIMESTAMP);"
    ].join(' ')
  })
  productCategoryFormSQL.value = forms.join('\n');

  (() => {
    const blob = new Blob([productCategoryFormSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "insert-new-product-category-form.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  const categories = input.productCategories.map(v => {
    return [
      "insert into `t_bill_product_category`",
      "(`aggregator`, `country_code`, `created_by`, `created_time`, `description`, `is_valid`, `name`, `product_category_code`, `secondary_category_code`, `updated_by`, `updated_time`, `variant`) values",
      "('" + v.aggregator + "', '" + v.countryCode + "', 'system', CURRENT_TIMESTAMP, '', '" + v.isValid + "', '" + v.name + "', '" + v.productCategoryCode + "', '" + v.secondaryCategoryCode + "', 'system', CURRENT_TIMESTAMP, '" + v.variant + "');"
    ].join(' ')
  });
  productCategorySQL.value = categories.join('\n');

  (() => {
    const blob = new Blob([productCategorySQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "insert-new-product-category.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  // UPDATE
  const productUpdate = input.products.map(v => {
    return "UPDATE `t_bill_product` SET `admin_fee` = '" + v.adminFee.toFixed(2) + "', `biller` = '" + v.biller + "', `is_admin_fee_enabled` = 'Y', `is_point_enabled` = 'N', `is_valid` = '" + v.isValid + "', `product_logo_url` = '" + (v.productLogoUrl || '') + "', `product_name` = '" + (v.productName || '') + "', `sort_no` = '" + v.sortNo + "', `transaction_type_code` = '" + v.transactionTypeCode + "', `updated_time` = CURRENT_TIMESTAMP WHERE `secondary_category_code` = '" + v.secondaryCategoryCode + "' AND `product_id` = '" + v.productId + "' AND `aggregator` = '" + v.aggregator + "';"
  })
  productUpdateSQL.value = productUpdate.join('\n');

  (() => {
    const blob = new Blob([productUpdateSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "update-product.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  const productDetailUpdate = input.productDetails.map(v => {
    let value = v.value
    const val = parseInt(value)
    if (!isNaN(val)) {
      value = val.toFixed(2)
    }
    return "UPDATE `t_bill_product_detail` SET `is_valid` = '" + v.isValid + "', `value` = '" + value + "' WHERE `bill_product_id` = '" + v.billProductId + "' AND `type` = '" + v.type + "';"
  })
  productDetailUpdateSQL.value = productDetailUpdate.join('\n');

  (() => {
    const blob = new Blob([productDetailUpdateSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "update-product-detail.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  const formsUpdate = input.productCategoryForms.map(v => {
    return "UPDATE `t_bill_product_category_form` SET `description` = '" + JSON.stringify(v.description) + "', `form_condition` = '" + v.formCondition + "', `form_type` = '" + v.formType + "', `is_valid` = '" + v.isValid + "', `label` = '" + JSON.stringify(v.formLabel) + "', `options` = '" + JSON.stringify(v.options) + "', `sort_no` = '" + v.sortNo + "', `updated_time` = CURRENT_TIMESTAMP WHERE `secondary_category_code` = '" + v.secondaryCategoryCode + "' AND `product_category_code` = '" + v.productCategoryCode + "' AND  `aggregator` = '" + v.aggregator + "' AND `form_key` = '" + v.formKey + "';"
  })
  productCategoryFormUpdateSQL.value = formsUpdate.join('\n');

  (() => {
    const blob = new Blob([productCategoryFormUpdateSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "update-product-category-form.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()

  const categoriesUpdate = input.productCategories.map(v => {
    return "UPDATE `t_bill_product_category` SET `country_code` = '" + v.countryCode + "', `description` = '', `is_valid` = '" + v.isValid + "', `name` = '" + v.name + "', `updated_time` = CURRENT_TIMESTAMP, `variant` = '" + v.variant + "' WHERE `secondary_category_code` = '" + v.secondaryCategoryCode + "' AND `product_category_code` = '" + v.productCategoryCode + "' AND `aggregator` = '" + v.aggregator + "';"
  });
  productCategoryUpdateSQL.value = categoriesUpdate.join('\n');

  (() => {
    const blob = new Blob([productCategoryUpdateSQL.value], { type: 'plain/text' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = "update-product-category.sql"
    link.click()
    URL.revokeObjectURL(link.href)
  })()
}

const resetImportFiles = () => {
  uploadImportRef.value!.clearFiles()
  importFilename.value = ''
  for (const idx in sheetMetadatas) {
    const sheet = sheetMetadatas[idx].sheet
    delete importSheetMasterData[sheet]
  }
}

const productSQL = ref<string>()
const productDetailSQL = ref<string>()
const productCategorySQL = ref<string>()
const productCategoryFormSQL = ref<string>()

const productUpdateSQL = ref<string>()
const productDetailUpdateSQL = ref<string>()
const productCategoryFormUpdateSQL = ref<string>()
const productCategoryUpdateSQL = ref<string>()

</script>

<template>
  <div>
    <a href="https://vuejs.org/" target="_blank">
      <img src="./assets/vue.svg" class="logo vue" alt="Vue logo" />
    </a>
    <h1><i>{{ quotes }}</i></h1>
  </div>
  <el-upload style="width: 1280px;" drag ref="uploadImportRef"
    accept=".xlsx, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" :on-change="onChangeImportFile"
    :auto-upload="false" :show-file-list="false" :multiple="false" :limit="1">
    <el-icon class="el-icon--upload"><upload-filled /></el-icon>
    <div class="el-upload__text">Drop excel file here or <em>click to load excel file</em></div>
  </el-upload>
  <h2> FILE - {{ importFilename }}</h2>
  <br />
  <button style="width: 150px; height: 100px; text-align: center; background-color: #42A5F5; color: white;" @click.prevent="submitImportFile">
    Generate
  </button>
  <br />
  <br />
  <h5 class="green-center">Product</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productSQL }}</textarea>
  <br />
  <h5 class="red-center">Product Update</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productUpdateSQL }}</textarea>
  <br />
  <h5 class="green-center">Product Detail</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productDetailSQL }}</textarea>
  <br />
  <h5 class="red-center">Product Detail Update</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productDetailUpdateSQL }}</textarea>
  <br />
  <h5 class="green-center">Product Category</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productCategorySQL }}</textarea>
  <br />
  <h5 class="red-center">Product Category Update</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productCategoryUpdateSQL }}</textarea>
  <br />
  <h5 class="green-center">Product Category Form</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productCategoryFormSQL }}</textarea>
  <br />
  <h5 class="red-center">Product Category Form Update</h5>
  <textarea style="width: 1280px; height: 500px;">{{ productCategoryFormUpdateSQL }}</textarea>
</template>

<style scoped>
.logo {
  height: 6em;
  padding: 1.5em;
  will-change: filter;
  transition: filter 300ms;
}

.logo:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}

.logo.vue:hover {
  filter: drop-shadow(0 0 2em #42b883aa);
}

.green-center {
  padding: 10px;
  background-color: #66BB6A;
  height: 50px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.red-center {
  padding: 10px;
  background-color: #F06292;
  height: 50px;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
