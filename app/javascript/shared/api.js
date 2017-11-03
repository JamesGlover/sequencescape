import axios from 'axios';

const API = axios.create({
  baseURL: `/api/v1`,
  headers: {
    'Accept': 'application/vnd.api+json',
    'Content-Type': 'application/vnd.api+json'
  }
});

export default API;
