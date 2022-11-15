import { AmplifyApiGraphQlResourceStackTemplate } from '@aws-amplify/cli-extensibility-helper';

export function override(resources: AmplifyApiGraphQlResourceStackTemplate) {
    // set the delta table TTL to one week
    resources.models['EpisodeData'].modelDatasource.dynamoDbConfig['deltaSyncConfig']['deltaSyncTableTtl'] = '10080'
}
