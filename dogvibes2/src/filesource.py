from track import Track
from collection import Collection

class FileSource:
    def __init__(self, name, directory):
        self.name = name
        self.directory = directory

        # create database of files
        self.collection = Collection()
        self.collection.index("/home/brizz/music/")

    def create_track_from_uri(self, uri):
        return self.collection.create_track_from_uri(uri)

    def search(self, query):
        return self.collection.search(query)
