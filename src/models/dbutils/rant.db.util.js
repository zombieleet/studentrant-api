export default class RantDbUtils {

    constructor(rantsCollection) {
        this.rantsCollection = rantsCollection;
    }

    async saveRant(data) {
        await (new this.rantsCollection(data).save());
        return await this.rantsCollection.findOne({ rantId: data.rantId }, {
	    _id: false,
	    __v: false
        }).lean();
    }

    async findOneRant(ops) {
        return await this.rantsCollection.findOne(
	    ops.query,
	    ops.project
        ).lean();
    }

    async deleteOneRant(rantId) {
        return await this.rantsCollection.updateOne(
	    { rantId },
	    { $set: { deleted: true } }
        ).lean();
    }
}
